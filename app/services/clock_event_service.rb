class ClockEventService
  class OutsideGeofenceError < StandardError; end

  def self.call(user:, organisation:, latitude:, longitude:)
    # Determine last event in this organisation
    last_event = ClockEvent.where(user: user, organisation: organisation).order(occurred_at: :desc).first

    # Decision logic
    event_type = if last_event.nil? || last_event.clock_out?
                   'clock_in'
                 else
                   'clock_out'
                 end

    # Calculate distance
    distance = DistanceCalculator.distance(latitude, longitude, organisation.latitude, organisation.longitude)

    # Geofence check
    raise OutsideGeofenceError, "Cannot clock #{event_type}: user is #{distance}m away, allowed radius is #{organisation.allowed_radius_meters}m" if distance > organisation.allowed_radius_meters

    # Create the ClockEvent
    ClockEvent.create!(
      user: user,
      organisation: organisation,
      event_type: event_type,
      occurred_at: Time.current,
      latitude: latitude,
      longitude: longitude,
      distance_from_org_meters: distance
    )
  end
end
