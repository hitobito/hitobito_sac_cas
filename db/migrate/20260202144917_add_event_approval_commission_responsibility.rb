# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddEventApprovalCommissionResponsibility < ActiveRecord::Migration[8.0]
  def change
    create_table :event_approval_commission_responsibilities do |t|
      t.belongs_to :sektion, null: false
      t.belongs_to :freigabe_komitee, null: false
      t.belongs_to :target_group, null: false
      t.belongs_to :discipline, null: false
      t.boolean :subito, null: false
      t.timestamps
    end

    add_index :event_approval_commission_responsibilities,
          [:sektion_id, :target_group_id, :discipline_id, :subito],
          unique: true,
          name: 'idx_unique_approval_responsibility'
  end
end
