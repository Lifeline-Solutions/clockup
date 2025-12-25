class CreateClockEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :clock_events, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :organisation, null: false, type: :uuid, foreign_key: true
      t.string :event_type, null: false
      t.datetime :occurred_at, null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.integer :distance_from_org_meters

      t.timestamps
    end

    add_index :clock_events, [:user_id, :occurred_at]
    add_index :clock_events, [:organisation_id, :occurred_at]
  end
end
