require 'httparty'

class WeatherService
  OPENWEATHER_KEY = ENV['OPENWEATHER_API_KEY']
  BASE_URL = 'https://api.openweathermap.org/data/2.5/onecall'.freeze

  # lat, lon are floats; cache_key is string (e.g. postal code)
  def initialize(lat, lon, cache_key)
    @lat = lat
    @lon = lon
    @cache_key = "weather:#{cache_key}"
  end

  # returns {ok: true, data: {...}, cached: true/false} or {ok:false, error: msg}
  def call
    return failure("Missing OpenWeather API key") if OPENWEATHER_KEY.blank?
    # check cache
    cached = Rails.cache.read(@cache_key)
    if cached.present?
      cached[:cached] = true
      return { ok: true, data: cached, cached: true }
    end

    resp = HTTParty.get(BASE_URL, query: {
      lat: @lat,
      lon: @lon,
      exclude: 'minutely,alerts',
      units: 'metric',
      appid: OPENWEATHER_KEY
    }, timeout: 10)

    unless resp.success?
      return failure("HTTP #{resp.code}: #{resp.parsed_response}")
    end

    # Map/extract relevant info (current temp, high/low today, next few days)
    body = resp.parsed_response

    data = {
      current: {
        temp_c: body.dig('current', 'temp'),
        feels_like_c: body.dig('current', 'feels_like'),
        humidity: body.dig('current', 'humidity'),
        weather: body.dig('current', 'weather')&.first&.slice('main','description','icon')
      },
      today: {
        temp_min_c: body.dig('daily', 0, 'temp', 'min'),
        temp_max_c: body.dig('daily', 0, 'temp', 'max')
      },
      daily: body['daily']&.first(5)&.map do |d|
        {
          dt: Time.at(d['dt']).utc.to_date.to_s,
          temp_min_c: d.dig('temp','min'),
          temp_max_c: d.dig('temp','max'),
          weather: d['weather']&.first&.slice('main','description','icon')
        }
      end
    }

    # write to cache for 30 minutes
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