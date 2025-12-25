class ClockEventService
  class OutsideGeofenceError < StandardError; end
  class DuplicateEventError < StandardError; end

  # user: User instance
  # organisation: Organisation instance
  # latitude, longitude: current user coordinates
  # event_type: optional, :clock_in or :clock_out
  #
  # Behaviour:
  # - If event_type is provided, it is respected (monolith buttons)
  # - If event_type is nil, it is inferred from the user's last event (mobile QR flow)
  def self.call(user:, organisation:, latitude:, longitude:, event_type: nil)
    # Determine last event in this organisation
    last_event = ClockEvent
      .where(user: user, organisation: organisation)
      .order(occurred_at: :desc)
      .first

    # Decide event type if not passed
    event_type ||= if last_event.nil? || last_event.clock_out?
                     :clock_in
                   else
                     :clock_out
                   end

    # Prevent duplicate consecutive events
    raise DuplicateEventError, "Cannot create duplicate consecutive #{event_type} event" if last_event&.event_type == event_type.to_s

    # Calculate distance
    distance = DistanceCalculator.distance(
      latitude,
      longitude,
      organisation.latitude,
      organisation.longitude
    )

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

    # Add lateness / early leave info for reporting (non-persisted helpers)
    clock_event.define_singleton_method(:late?) do
      clock_event.clock_in? &&
        organisation.respond_to?(:work_start_time_for) &&
        clock_event.occurred_at >
          organisation.work_start_time_for(clock_event.occurred_at.to_date)
    end

    clock_event.define_singleton_method(:early_leave?) do
      clock_event.clock_out? &&
        organisation.respond_to?(:work_end_time_for) &&
        clock_event.occurred_at <
          organisation.work_end_time_for(clock_event.occurred_at.to_date)
    end

    clock_event
  end
end
