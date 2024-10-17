class AddStateToParticipation < ActiveRecord::Migration[6.1]
  def change
    add_column :event_participations, :invoice_state, :string
  end
end
