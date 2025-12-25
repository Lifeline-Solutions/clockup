puts "Seeding organisations, users, roles, and clock events..."

# Clear existing data for a fresh, deterministic seed
ClockEvent.delete_all
User.delete_all
Organisation.delete_all
Role.delete_all

# Roles
admin_role = Role.create!(name: 'admin')

# Organisations (with timezone, geofence, and working hours)
org1 = Organisation.create!(
  name: 'Clockup HQ',
  latitude: -26.2041,
  longitude: 28.0473,
  allowed_radius_meters: 150,
  work_start_time: Time.parse('09:00'),
  work_end_time: Time.parse('17:00'),
  timezone: 'Africa/Johannesburg'
)

org2 = Organisation.create!(
  name: 'Remote Branch',
  latitude: -1.2921,
  longitude: 36.8219,
  allowed_radius_meters: 200,
  work_start_time: Time.parse('06:00'),
  work_end_time: Time.parse('16:00'),
  timezone: 'Africa/Nairobi'
)

# Users
admin_user = User.create!(
  email: 'nemwel@example.com',
  password: 'root man',
  organisation: org1
)
admin_user.add_role(:admin)

org_admin = User.create!(
  email: 'orgadmin@example.com',
  password: 'OrgAdmin!123',
  organisation: org1
)
org_admin.add_role(:admin, org1)

staff_normal = User.create!(
  email: 'staff.normal@example.com',
  password: 'StaffNorm!123',
  organisation: org1
)

staff_late = User.create!(
  email: 'staff.late@example.com',
  password: 'StaffLate!123',
  organisation: org1
)

staff_early = User.create!(
  email: 'staff.early@example.com',
  password: 'StaffEarly!123',
  organisation: org1
)

branch_staff = User.create!(
  email: 'branch.staff@example.com',
  password: 'BranchStaff!123',
  organisation: org2
)

# Helper to build occurred_at in organisation timezone
def org_time(org, hour:, min: 0)
  org.time_zone.parse(Date.current.to_s).change(hour: hour, min: min)
end

# Now in org timezone
def now_in_org(org)
  org.time_zone.now
end

# Coordinates near organisation HQ (inside geofence)
near_hq = ->(org) { [org.latitude, org.longitude] }

# Create clock events for today covering scenarios
lat, lon = near_hq.call(org1)

# Normal staff: on-time clock in (09:00), conditional clock out (17:00 if past now)
ClockEvent.create!(user: staff_normal, organisation: org1, event_type: :clock_in, occurred_at: org_time(org1, hour: 9, min: 0), latitude: lat, longitude: lon, distance_from_org_meters: DistanceCalculator.distance(lat, lon, org1.latitude, org1.longitude))
if now_in_org(org1) >= org1.work_end_time_for(Date.current)
  ClockEvent.create!(user: staff_normal, organisation: org1, event_type: :clock_out, occurred_at: org_time(org1, hour: 17, min: 0), latitude: lat, longitude: lon, distance_from_org_meters: DistanceCalculator.distance(lat, lon, org1.latitude, org1.longitude))
end

# Late staff: clock in at 09:20, conditional normal clock out at 17:05
ClockEvent.create!(user: staff_late, organisation: org1, event_type: :clock_in, occurred_at: org_time(org1, hour: 9, min: 20), latitude: lat, longitude: lon, distance_from_org_meters: DistanceCalculator.distance(lat, lon, org1.latitude, org1.longitude))
if now_in_org(org1) >= org_time(org1, hour: 17, min: 5)
  ClockEvent.create!(user: staff_late, organisation: org1, event_type: :clock_out, occurred_at: org_time(org1, hour: 17, min: 5), latitude: lat, longitude: lon, distance_from_org_meters: DistanceCalculator.distance(lat, lon, org1.latitude, org1.longitude))
end

# Early leave staff: clock in normal, conditional early clock out at 16:30
ClockEvent.create!(user: staff_early, organisation: org1, event_type: :clock_in, occurred_at: org_time(org1, hour: 9, min: 0), latitude: lat, longitude: lon, distance_from_org_meters: DistanceCalculator.distance(lat, lon, org1.latitude, org1.longitude))
if now_in_org(org1) >= org_time(org1, hour: 16, min: 30)
  ClockEvent.create!(user: staff_early, organisation: org1, event_type: :clock_out, occurred_at: org_time(org1, hour: 16, min: 30), latitude: lat, longitude: lon, distance_from_org_meters: DistanceCalculator.distance(lat, lon, org1.latitude, org1.longitude))
end

# Branch staff: on-time according to branch hours (06:00–16:00), conditional clock out
lat2, lon2 = near_hq.call(org2)
ClockEvent.create!(user: branch_staff, organisation: org2, event_type: :clock_in, occurred_at: org_time(org2, hour: 6, min: 0), latitude: lat2, longitude: lon2, distance_from_org_meters: DistanceCalculator.distance(lat2, lon2, org2.latitude, org2.longitude))
if now_in_org(org2) >= org2.work_end_time_for(Date.current)
  ClockEvent.create!(user: branch_staff, organisation: org2, event_type: :clock_out, occurred_at: org_time(org2, hour: 16, min: 0), latitude: lat2, longitude: lon2, distance_from_org_meters: DistanceCalculator.distance(lat2, lon2, org2.latitude, org2.longitude))
end

puts "Seed complete."
puts "Admin login: email=nemwel@example.com password=root man"
puts "Org admin login: email=orgadmin@example.com password=OrgAdmin!123"
puts "Staff (normal): email=staff.normal@example.com password=StaffNorm!123"
puts "Staff (late): email=staff.late@example.com password=StaffLate!123"
puts "Staff (early): email=staff.early@example.com password=StaffEarly!123"
puts "Branch staff: email=branch.staff@example.com password=BranchStaff!123"

puts "Org1 (Clockup HQ) timezone: #{org1.timezone}, start: #{org1.work_start_time.strftime('%H:%M')}, end: #{org1.work_end_time.strftime('%H:%M')}"
puts "Org2 (Remote Branch) timezone: #{org2.timezone}, start: #{org2.work_start_time.strftime('%H:%M')}, end: #{org2.work_end_time.strftime('%H:%M')}"