class Organisation < ApplicationRecord
  # Ensure every organisation has a unique QR token before validation.
  # This token is used for clock-in / clock-out operations and prevents
  # nil values or database constraint violations during record creation.
  before_validation :generate_clock_qr_token, on: :create

  # Associations
  has_many :users, dependent: :destroy
  has_many :clock_events, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :latitude, presence: true,
                       numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, message: 'must be between -90 and 90' }
  validates :longitude, presence: true,
                        numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, message: 'must be between -180 and 180' }
  validates :allowed_radius_meters, presence: true,
                                    numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1000, message: 'must be a positive number less than or equal to 1000 meters' }
  validates :clock_qr_token, presence: true, uniqueness: true
  validates :work_start_time, :work_end_time, presence: true

  # Returns a DateTime object for the organisation's start time on a given date
  def work_start_time_for(date)
    DateTime.new(date.year, date.month, date.day, work_start_time.hour, work_start_time.min, work_start_time.sec, work_start_time.zone)
  end

  # Returns a DateTime object for the organisation's end time on a given date
  def work_end_time_for(date)
    DateTime.new(date.year, date.month, date.day, work_end_time.hour, work_end_time.min, work_end_time.sec, work_end_time.zone)
  end

  private

  # we can later rotate this token if needed via admin console
  def generate_clock_qr_token
    self.clock_qr_token ||= SecureRandom.hex(10) # 20-character token
  end

  def regenerate_clock_qr_token!
    begin
      self.clock_qr_token = SecureRandom.hex(10)
    end while self.class.exists?(clock_qr_token: clock_qr_token)

    save!
  end
end
