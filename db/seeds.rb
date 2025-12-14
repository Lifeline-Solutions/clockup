# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Role.find_or_create_by!(name: 'super admin')


organisation = Organisation.find_or_create_by!(name: 'Solidus') do |c|
  c.email = 'admin@solidus.com'
end

user = User.find_or_initialize_by(email: 'abolger254@gmail.com')
user.assign_attributes(
  password: user.encrypted_password.present? ? user.password : 'password',
  confirmed_at: user.confirmed_at || DateTime.now,
  confirmation_sent_at: user.confirmation_sent_at || DateTime.now,
  first_name: user.first_name.presence || 'Jay',
  last_name: user.last_name.presence || 'Admin',
  organisation_id: user.organisation_id || organisation.id
)

user.save!
user.add_role('super admin') unless user.has_role?('super admin')