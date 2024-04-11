class AddCancelStatementToEventParticipations < ActiveRecord::Migration[6.1]
  def change
    change_table(:event_participations) do |t|
      t.text :cancel_statement
    end
  end
end
