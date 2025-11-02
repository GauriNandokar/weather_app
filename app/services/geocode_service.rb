class GeocodeService
  # Returns hash with :ok, :lat, :lon, :postal_code, :display_name or :error
  def initialize(address)
    @address = address
  end

  def call
    results = Geocoder.search(@address)
    if results.blank?
      return { ok: false, error: "No geocoding results" }
    end

    r = results.first
    lat = r.latitude
    lon = r.longitude
    # Try to glean a postal code
    postal = nil
    # Geocoder result stores address components in #data on many services
    if r.respond_to?(:postal_code) && r.postal_code.present?
      postal = r.postal_code
    elsif r.data && r.data['address'] && r.data['address']['postcode']
      postal = r.data['address']['postcode']
    else
      # Try to parse from formatted address as fallback (rare)
      if r.address && (m = r.address.match(/(\d{5}(?:-\d{4})?)/))
        postal = m[1]
      end
    end

    display_name = r.address || r.formatted_address || @address

    { ok: true, lat: lat, lon: lon, postal_code: postal, display_name: display_name }
  rescue StandardError => e
    { ok: false, error: e.message }
  end
end