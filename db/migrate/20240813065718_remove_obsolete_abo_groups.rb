class RemoveObsoleteAboGroups < ActiveRecord::Migration[6.1]
  def up
    execute "DELETE FROM roles WHERE type = 'Group::AboMagazin::Autor'"
    execute "DELETE FROM groups WHERE type = 'Group::Abonnenten'"
  end
end
