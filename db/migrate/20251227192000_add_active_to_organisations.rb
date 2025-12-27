class AddActiveToOrganisations < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :active, :boolean, null: false, default: true
  end
end
