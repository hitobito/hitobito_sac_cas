# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class TourEssentialsOrderNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column :event_disciplines, :order, :integer, null: false, default: 0
    change_column :event_fitness_requirements, :order, :integer, null: false, default: 0
    change_column :event_target_groups, :order, :integer, null: false, default: 0
    change_column :event_technical_requirements, :order, :integer, null: false, default: 0
    change_column :event_traits, :order, :integer, null: false, default: 0
  end
end
