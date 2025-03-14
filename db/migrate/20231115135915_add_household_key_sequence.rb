# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class AddHouseholdKeySequence < ActiveRecord::Migration[6.1]
  # We use an offset of 500'000 to avoid collisions with family ids imported from navision.
  HOUSEHOLD_KEY_STARTVALUE = 500_000

  def up
    if ActiveRecord::Base.connection.adapter_name.downcase =~ /mysql/
      execute "INSERT IGNORE INTO sequences (name, current_value) VALUES ('#{SacCas::Household::HOUSEHOLD_KEY_SEQUENCE}', #{HOUSEHOLD_KEY_STARTVALUE})"
    end
  end

  def down
    execute "DELETE FROM sequences WHERE name = '#{SacCas::Household::HOUSEHOLD_KEY_SEQUENCE}'"
  end
end
