# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateEventApprovalTable < ActiveRecord::Migration[8.0]
  def change
    create_table :event_approvals do |t|
      t.belongs_to :event, null: false
      t.belongs_to :freigabe_komitee
      t.belongs_to :approval_kind
      t.boolean :approved, null: false, default: true
      t.belongs_to :creator

      t.datetime :created_at
    end

    add_index :event_approvals,
          [:event_id, :freigabe_komitee_id, :approval_kind_id],
          unique: true,
          name: 'idx_unique_approvals'
  end
end
