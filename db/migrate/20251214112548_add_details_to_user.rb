class AddDetailsToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :personal_number, :string
    add_column :users, :national_id, :string
    add_column :users, :phone_number, :string
  end
end
