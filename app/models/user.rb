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

  private

  def generate_api_token
    self.api_token ||= loop do
      token = SecureRandom.hex(20) # 40-character token
      break token unless self.class.exists?(api_token: token)
    end
  end
end
