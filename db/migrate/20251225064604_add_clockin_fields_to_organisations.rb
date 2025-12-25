class AddClockinFieldsToOrganisations < ActiveRecord::Migration[8.1]
  def change
    # allows lat/lng like -1.286389 or 36.817223
    add_column :organisations, :latitude, :decimal, precision: 10, scale: 6
    add_column :organisations, :longitude, :decimal, precision: 10, scale: 6
    add_column :organisations, :allowed_radius_meters, :integer, default: 100
    add_column :organisations, :clock_qr_token, :string

    # Unique index ensures no two organisations have the same QR token
    add_index :organisations, :clock_qr_token, unique: true, where: "clock_qr_token IS NOT NULL"
  end
end
