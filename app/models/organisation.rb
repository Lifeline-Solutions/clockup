class Organisation < ApplicationRecord
  resourcify
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
  validates :timezone, presence: true

  def time_zone
    ActiveSupport::TimeZone[timezone] || Time.zone
  end

  # Returns a DateTime object for the organisation's start time on a given date
  def work_start_time_for(date)
    tz = time_zone
    tz.parse(date.to_s).change(hour: work_start_time.hour, min: work_start_time.min, sec: work_start_time.sec)
  end

  # Returns a DateTime object for the organisation's end time on a given date
  def work_end_time_for(date)
    tz = time_zone
    tz.parse(date.to_s).change(hour: work_end_time.hour, min: work_end_time.min, sec: work_end_time.sec)
  end

  private

  # we can later rotate this token if needed via admin console
  def generate_clock_qr_token
    self.clock_qr_token ||= SecureRandom.hex(10) # 20-character token
  end

  def regenerate_clock_qr_token!
    loop do
      self.clock_qr_token = SecureRandom.hex(10)
      break unless self.class.exists?(clock_qr_token: clock_qr_token)
    end

    save!
  end
end
