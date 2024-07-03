class CreateTerminationReasons < ActiveRecord::Migration[6.1]
  def change
    create_table :termination_reasons do |t|
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        TerminationReason.create_translation_table! text: {type: :text, null: false}
      end

      dir.down do
        TerminationReason.drop_translation_table!
      end
    end

    change_table :roles do |t|
      t.references :termination_reason, foreign_key: true
    end
  end
end
