class DistanceCalculator
  EARTH_RADIUS_METERS = 6_371_000.0 # average Earth radius in meters

  # Calculates distance in meters between two coordinates
  # Params:
  # +lat1+, +lon1+:: latitude and longitude of first point in decimal degrees
  # +lat2+, +lon2+:: latitude and longitude of second point in decimal degrees
  def self.distance(lat1, lon1, lat2, lon2)
    return 0 if [lat1, lon1, lat2, lon2].any?(&:nil?)

    # Convert degrees to radians
    lat1_rad = lat1.to_f * Math::PI / 180
    lon1_rad = lon1.to_f * Math::PI / 180
    lat2_rad = lat2.to_f * Math::PI / 180
    lon2_rad = lon2.to_f * Math::PI / 180

    delta_lat = lat2_rad - lat1_rad
    delta_lon = lon2_rad - lon1_rad

    a = (Math.sin(delta_lat / 2)**2) + (Math.cos(lat1_rad) * Math.cos(lat2_rad) * (Math.sin(delta_lon / 2)**2))
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    (EARTH_RADIUS_METERS * c).round
  end
end
