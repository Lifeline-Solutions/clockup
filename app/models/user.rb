class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  belongs_to :organisation
  has_many :clock_events, dependent: :destroy

  # Ensure API token is generated before create
  before_create :generate_api_token

  # Display helpers
  def name
    full = [first_name, last_name].compact.join(' ')
    full.presence || email
  end

  # Derived state helpers
  def latest_clock_event_for(org = organisation)
    clock_events.where(organisation_id: org.id).order(occurred_at: :desc).limit(1).first
  end

  def clocked_in?(org = organisation)
    evt = latest_clock_event_for(org)
    evt&.clock_in? || false
  end

  def current_status(org = organisation)
    clocked_in?(org) ? :clocked_in : :clocked_out
  end

  private

  def generate_api_token
    self.api_token ||= loop do
      token = SecureRandom.hex(20) # 40-character token
      break token unless self.class.exists?(api_token: token)
    end
  end
end
