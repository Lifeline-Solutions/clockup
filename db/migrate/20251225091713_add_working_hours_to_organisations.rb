class AddWorkingHoursToOrganisations < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :work_start_time, :time, null: false, default: "09:00"
    add_column :organisations, :work_end_time, :time, null: false, default: "17:00"
  end
end
