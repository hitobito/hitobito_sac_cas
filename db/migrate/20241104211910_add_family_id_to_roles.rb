class AddFamilyIdToRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :roles, :family_id, :string
  end
end
