# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddTechnicalRequirmentIdToActivity < ActiveRecord::Migration[8.0]
  def change
    add_reference :event_activities, :technical_requirement, null: true, foreign_key: false, type: :integer
  end
end
