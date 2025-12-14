class AddOrganisationToUser < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :organisation, null: false, foreign_key: true, type: :uuid
  end
end
