# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddNullsNotDistinctToEventApprovalsIndex < ActiveRecord::Migration[8.0]
  COLUMNS = [:event_id, :freigabe_komitee_id, :approval_kind_id].freeze

  def change
    remove_index :event_approvals, COLUMNS, unique: true, name: "idx_unique_approvals"
    add_index :event_approvals, COLUMNS, unique: true, nulls_not_distinct: true,
      name: "idx_unique_approvals"
  end
end
