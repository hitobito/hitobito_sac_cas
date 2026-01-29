# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateEventApprovalKinds < ActiveRecord::Migration[8.0]
  def change
    create_table :event_approval_kinds do |t|
      t.integer :order

      t.timestamps
      t.datetime :deleted_at
    end

    create_table :roles_event_approval_kinds, id: false do |t|
      t.belongs_to :role, null: false
      t.belongs_to :approval_kind, null: false
      t.index [:role_id, :approval_kind_id], unique: true
    end

    reversible do |dir|
      dir.up do
        Event::ApprovalKind.create_translation_table!(
          name: {type: :string, null: false},
          short_description: {type: :string, null: true}
        )
        add_index :event_approval_kind_translations, :name, unique: true
      end

      dir.down do
        Event::ApprovalKind.drop_translation_table!
      end
    end
  end
end
