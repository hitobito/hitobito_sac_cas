# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class AddSubsidyToEventParticipations < ActiveRecord::Migration[6.1]
  def change
    change_table(:event_participations) do |t|
      t.boolean :subsidy, default: false, null: false
    end
  end
end
