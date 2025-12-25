class Organisation < ApplicationRecord
  before_create :generate_clock_qr_token

  private

  # we can later rotate this token if needed via admin console
  def generate_clock_qr_token
    self.clock_qr_token ||= SecureRandom.hex(10) # 20-character token
  end
end
