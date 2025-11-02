require 'httparty'

class WeatherService
  OPENWEATHER_KEY = ENV['OPENWEATHER_API_KEY']
  CURRENT_URL  = 'https://api.openweathermap.org/data/2.5/weather'.freeze
  FORECAST_URL = 'https://api.openweathermap.org/data/2.5/forecast'.freeze

  # lat, lon are floats; cache_key is string (e.g. postal code)
  def initialize(lat, lon, cache_key)
    @lat = lat
    @lon = lon
    @cache_key = "weather:#{cache_key}"
  end

  # returns {ok: true, data: {...}, cached: true/false} or {ok:false, error: msg}
  def call
    return failure("Missing OpenWeather API key") if OPENWEATHER_KEY.blank?

    # Check cache
    cached = Rails.cache.read(@cache_key)
    if cached.present?
      cached[:cached] = true
      return { ok: true, data: cached, cached: true }
    end

    # --- Fetch current weather ---
    current_resp = HTTParty.get(CURRENT_URL, query: {
      lat: @lat,
      lon: @lon,
      units: 'metric',
      appid: OPENWEATHER_KEY
    }, timeout: 10)

    unless current_resp.success?
      return failure("Current weather error: HTTP #{current_resp.code}: #{current_resp.parsed_response}")
    end

    # --- Fetch forecast (5-day/3-hour intervals) ---
    forecast_resp = HTTParty.get(FORECAST_URL, query: {
      lat: @lat,
      lon: @lon,
      units: 'metric',
      appid: OPENWEATHER_KEY
    }, timeout: 10)

    unless forecast_resp.success?
      return failure("Forecast error: HTTP #{forecast_resp.code}: #{forecast_resp.parsed_response}")
    end

    current_body  = current_resp.parsed_response
    forecast_body = forecast_resp.parsed_response

    # --- Extract and transform data ---
    data = {
      current: {
        temp_c: current_body.dig('main', 'temp'),
        feels_like_c: current_body.dig('main', 'feels_like'),
        humidity: current_body.dig('main', 'humidity'),
        weather: current_body['weather']&.first&.slice('main', 'description', 'icon')
      },
      today: {
        temp_min_c: current_body.dig('main', 'temp_min'),
        temp_max_c: current_body.dig('main', 'temp_max')
      },
      daily: forecast_body['list']&.group_by { |f| Time.at(f['dt']).utc.to_date }&.map do |date, entries|
        {
          dt: date.to_s,
          temp_min_c: entries.map { |e| e.dig('main', 'temp_min') }.min,
          temp_max_c: entries.map { |e| e.dig('main', 'temp_max') }.max,
          weather: entries.first['weather']&.first&.slice('main', 'description', 'icon')
        }
      end&.first(5)
    }

    # --- Cache result for 30 minutes ---
    data_with_meta = data.merge(fetched_at: Time.now.utc)
    Rails.cache.write(@cache_key, data_with_meta, expires_in: 30.minutes)

    { ok: true, data: data_with_meta, cached: false }
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    failure("Timeout talking to weather service: #{e.message}")
  rescue StandardError => e
    failure(e.message)
  end

  private

  def failure(msg)
    { ok: false, error: msg }
  end
end