require 'rails_helper'

RSpec.describe WeatherService, type: :service do
  let(:lat)        { 19.0760 }   # Mumbai latitude
  let(:lon)        { 72.8777 }   # Mumbai longitude
  let(:cache_key)  { '400001' }
  let(:service)    { described_class.new(lat, lon, cache_key) }
  let(:api_key)    { 'dummy-api-key' }

  before do
    # Stub ENV variable for API key
    stub_const('WeatherService::OPENWEATHER_KEY', api_key)
    Rails.cache.clear
  end

  describe '#call' do
    context 'when API key is missing' do
      before { stub_const('WeatherService::OPENWEATHER_KEY', nil) }

      it 'returns failure message' do
        result = service.call
        expect(result[:ok]).to be false
        expect(result[:error]).to match(/Missing OpenWeather API key/)
      end
    end

    context 'when API responses are successful' do
      let(:current_body) do
        {
          'main' => { 'temp' => 30.5, 'feels_like' => 32, 'humidity' => 70, 'temp_min' => 29, 'temp_max' => 33 },
          'weather' => [{ 'main' => 'Clear', 'description' => 'sunny', 'icon' => '01d' }]
        }
      end

      let(:forecast_body) do
        {
          'list' => [
            { 'dt' => Time.now.to_i, 'main' => { 'temp_min' => 28, 'temp_max' => 34 },
              'weather' => [{ 'main' => 'Clear', 'description' => 'sunny', 'icon' => '01d' }] }
          ]
        }
      end

      before do
        stub_request(:get, WeatherService::CURRENT_URL)
          .with(query: hash_including(appid: api_key))
          .to_return(status: 200, body: current_body.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, WeatherService::FORECAST_URL)
          .with(query: hash_including(appid: api_key))
          .to_return(status: 200, body: forecast_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns weather data and caches it' do
        result = service.call

        expect(result[:ok]).to be true
        expect(result[:cached]).to be false
        expect(result[:data][:current][:temp_c]).to eq(30.5)

        # Check data is written to cache
        cached_data = Rails.cache.read("weather:#{cache_key}")
        expect(cached_data).not_to be_nil
      end

      it 'returns cached data on subsequent calls' do
        first_call = service.call
        second_call = service.call

        expect(second_call[:ok]).to be true
        expect(second_call[:cached]).to be true
        expect(second_call[:data][:current][:temp_c]).to eq(first_call[:data][:current][:temp_c])
      end
    end

    context 'when API returns 401 error' do
      before do
        stub_request(:get, WeatherService::CURRENT_URL)
          .with(query: hash_including(appid: api_key))
          .to_return(status: 401, body: { message: 'Invalid API key' }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, WeatherService::FORECAST_URL)
          .with(query: hash_including(appid: api_key))
          .to_return(status: 401, body: { message: 'Invalid API key' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns failure with proper error message' do
        result = service.call
        expect(result[:ok]).to be false
        expect(result[:error]).to match(/HTTP 401/)
      end
    end
  end
end
