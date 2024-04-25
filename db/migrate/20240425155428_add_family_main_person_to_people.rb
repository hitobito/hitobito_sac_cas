class AddFamilyMainPersonToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :family_main_person, :boolean, default: false
  end
end
