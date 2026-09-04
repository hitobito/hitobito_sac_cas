# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddEmergencyContactsToPeople < ActiveRecord::Migration[8.0]
  def change
    change_table :people, bulk: true do |t|
      t.string :emergency_contact_1_name,  null: true
      t.string :emergency_contact_1_phone, null: true
      t.string :emergency_contact_2_name,  null: true
      t.string :emergency_contact_2_phone, null: true
    end
  end
end
