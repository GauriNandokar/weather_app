class WeatherController < ApplicationController
  # Show form
  def index; end

  # Handle form submit
  def forecast
    address = params[:address].to_s.strip
    if address.blank?
      redirect_to root_path, alert: "Please provide an address or ZIP code."
      return
    end

    # geocode the address
    geocode_result = GeocodeService.new(address).call

    unless geocode_result[:ok]
      redirect_to root_path, alert: "Cannot geocode address: #{geocode_result[:error]}"
      return
    end

    # get cache key (prefer postal code)
    cache_key = geocode_result[:postal_code] || "latlon:#{geocode_result[:lat]},#{geocode_result[:lon]}"

    # fetch weather (the service returns {data:..., cached: true/false})
    weather_result = WeatherService.new(geocode_result[:lat], geocode_result[:lon], cache_key).call

    if weather_result[:ok]
      @forecast = weather_result[:data]
      @from_cache = weather_result[:cached]
      @location_name = geocode_result[:display_name] || address
      render :index
    else
      redirect_to root_path, alert: "Weather API error: #{weather_result[:error]}"
    end
  end
end