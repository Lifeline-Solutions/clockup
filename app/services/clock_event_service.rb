class ClockEventService
  class OutsideGeofenceError < StandardError; end
  class DuplicateEventError < StandardError; end

  # user: User instance
  # organisation: Organisation instance
  # latitude, longitude: current user coordinates
  # event_type: :clock_in or :clock_out
  def self.call(user:, organisation:, latitude:, longitude:, event_type:)
    # Prevent duplicate consecutive events
    last_event = ClockEvent.where(user: user, organisation: organisation).order(occurred_at: :desc).first
    raise DuplicateEventError, "Cannot create duplicate consecutive #{event_type} event" if last_event&.event_type == event_type.to_s

    # Calculate distance
    distance = DistanceCalculator.distance(latitude, longitude, organisation.latitude, organisation.longitude)

    # Geofence check
    if distance > organisation.allowed_radius_meters
      raise OutsideGeofenceError,
            "Cannot clock #{event_type}: user is #{distance}m away, allowed radius is #{organisation.allowed_radius_meters}m"
    end

    # Create ClockEvent
    clock_event = ClockEvent.create!(
      user: user,
      organisation: organisation,
      event_type: event_type,
      occurred_at: Time.current,
      latitude: latitude,
      longitude: longitude,
      distance_from_org_meters: distance
    )

    # Add lateness/early_leave info for reporting
    clock_event.define_singleton_method(:late?) { clock_event.clock_in? && clock_event.occurred_at > organisation.work_start_time_for(clock_event.occurred_at.to_date) }
    clock_event.define_singleton_method(:early_leave?) { clock_event.clock_out? && clock_event.occurred_at < organisation.work_end_time_for(clock_event.occurred_at.to_date) }

    clock_event
  end
end
