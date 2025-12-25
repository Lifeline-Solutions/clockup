class ClockEventService
  class OutsideGeofenceError < StandardError; end
  class DuplicateEventError < StandardError; end

  def self.call(user:, organisation:, latitude:, longitude:)
    # Get last event for this user in this organisation
    last_event = ClockEvent.where(user: user, organisation: organisation).order(occurred_at: :desc).first

    # Decide event type automatically
    event_type = if last_event.nil? || last_event.clock_out?
                   :clock_in
                 else
                   :clock_out
                 end

    # Prevent duplicate consecutive events
    raise DuplicateEventError, "Cannot create duplicate consecutive #{event_type} event" if last_event&.event_type == event_type.to_s

    # Calculate distance from organisation
    distance = DistanceCalculator.distance(latitude, longitude, organisation.latitude, organisation.longitude)

    # Check geofence
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
