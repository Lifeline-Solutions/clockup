class ClockEvent < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :organisation

  # Enum for event type
  enum :event_type, { clock_in: 'clock_in', clock_out: 'clock_out' }

  # Validations
  validates :user, :organisation, :event_type, :occurred_at, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :distance_from_org_meters, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Check if clock-in is late compared to organisation working hours
  def late?
    return false unless clock_in?

    occurred_at > organisation.work_start_time_for(occurred_at.to_date)
  end

  # Check if clock-out is early compared to organisation working hours
  def early_leave?
    return false unless clock_out?

    occurred_at < organisation.work_end_time_for(occurred_at.to_date)
  end
end
