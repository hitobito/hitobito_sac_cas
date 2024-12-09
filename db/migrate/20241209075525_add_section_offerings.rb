class AddSectionOfferings < ActiveRecord::Migration[7.0]
  def change
    create_table(:section_offerings) do |t|
      t.datetime :deleted_at
      t.timestamps
    end

    create_join_table(:groups, :section_offerings) do |t|
      t.index [:group_id, :section_offering_id], unique: true, name: 'index_groups_section_offerings_on_group_and_offering'
    end

    reversible do |dir|
      dir.up do
        SectionOffering.create_translation_table! title: { type: :string, null: false }
      end
      dir.down do
        SectionOffering.drop_translation_table!
      end
    end
  end
end
