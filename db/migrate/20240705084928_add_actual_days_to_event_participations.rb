# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddActualDaysToEventParticipations < ActiveRecord::Migration[6.1]
  def change
    add_column :event_participations, :actual_days, :decimal, precision: 4, scale: 1
  end
end
