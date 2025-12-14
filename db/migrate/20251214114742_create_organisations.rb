class CreateOrganisations < ActiveRecord::Migration[8.1]
  def change
    create_table :organisations, id: :uuid do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
