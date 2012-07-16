module MapsAPI
  MAPS_URL = 'https://maps.googleapis.com/maps/api/directions/json'
  DEFAULTS = {:sensor => false}

  def self.get(opts = {})
    JSON.parse(RestClient.get(MAPS_URL, :params => DEFAULTS.merge(opts)))
  end

  def self.first_leg(data)
    data['routes'].first['legs'].first
  end
end