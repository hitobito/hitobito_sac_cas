# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddPriceCategoryTogglesToEvent < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :special_may_apply, :boolean, null: false, default: true
    add_column :events, :member_may_apply, :boolean, null: false, default: true
    add_column :events, :regular_may_apply, :boolean, null: false, default: true
  end
end
