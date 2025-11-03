require 'rails_helper'

RSpec.describe "Weather", type: :request do
  before do
    allow(Geocoder).to receive(:search).and_return([
      double(latitude: 12.34, longitude: 56.78, address: "Test Addr",
             data: { 'address' => { 'postcode' => '99999' } })
    ])

    fake_weather_data = {
      current: {
        temp_c: 15,
        feels_like_c: 14,
        humidity: 50,
        weather: { 'main' => 'Clear', 'description' => 'clear sky' } # HASH not array
      },
      today: {
        temp_min_c: 10,
        temp_max_c: 20
      },
      daily: [
        {
          dt: Date.today.to_s,
          temp_min_c: 10,
          temp_max_c: 20,
          weather: { 'description' => 'cloudy' } # HASH again
        }
      ]
    }

    fake_service = instance_double(
      WeatherService,
      call: { ok: true, data: fake_weather_data, cached: false }
    )
    allow(WeatherService).to receive(:new).and_return(fake_service)
  end

  it "renders the forecast page successfully" do
    post forecast_path, params: { address: 'Test' }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('clear sky')
    expect(response.body).to include('Low: 10')
  end
end