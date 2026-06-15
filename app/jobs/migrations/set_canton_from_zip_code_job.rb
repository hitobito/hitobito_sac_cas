# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Migrations
  class SetCantonFromZipCodeJob < BaseJob
    def perform
      ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE people
        INNER JOIN locations ON locations.zip_code = people.zip_code
        SET people.canton = locations.canton
        WHERE people.canton IS NULL
          AND people.country = 'CH'
          AND people.zip_code IS NOT NULL
          AND people.zip_code != ''
      SQL
    end
  end
end
