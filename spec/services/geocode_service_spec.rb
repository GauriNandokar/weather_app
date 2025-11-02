require 'rails_helper'

RSpec.describe GeocodeService do
  it "returns geocode info for a known address" do
    # Use a simple test double for Geocoder to avoid external call
    allow(Geocoder).to receive(:search).and_return([
      double(latitude: 40.7128, longitude: -74.0060, address: "New York, NY", data: {'address' => {'postcode' => '10007'}})
    ])

    res = GeocodeService.new("New York").call
    expect(res[:ok]).to be true
    expect(res[:lat]).to eq 40.7128
    expect(res[:postal_code]).to eq '10007'
  end

  it "handles no results" do
    allow(Geocoder).to receive(:search).and_return([])
    res = GeocodeService.new("asdfasfdasdf").call
    expect(res[:ok]).to be false
  end
end