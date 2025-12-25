class AddTimezoneToOrganisations < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :timezone, :string, null: false, default: 'UTC'
  end
end
