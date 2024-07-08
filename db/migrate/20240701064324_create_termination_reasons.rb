# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateTerminationReasons < ActiveRecord::Migration[6.1]
  def change
    create_table :termination_reasons do |t|
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        TerminationReason.create_translation_table! text: { type: :text, null: false }
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
