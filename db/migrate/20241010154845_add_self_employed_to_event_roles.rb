class AddSelfEmployedToEventRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :event_roles, :self_employed, :boolean, default: false
  end
end
