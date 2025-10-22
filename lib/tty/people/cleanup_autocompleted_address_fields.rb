# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  class People
    class CleanupAutocompletedAddressFields
      prepend TTY::Command

      BadData = Data.define(:column, :value) do
        def scope = Person.where("#{column} = #{value}")

        def fix!
          puts "fixing #{scope.count} #{value} as #{column}"
          scope.update_all(column => nil)
        end
      end

      PROBLEMS = [
        BadData.new(:postbox, :zip_code),
        BadData.new(:address_care_of, :town),
        BadData.new(:address_care_of, "street||' '||housenumber")
      ]

      self.description = "Solves 3 Address Autocompletion Problems on Person"

      def run(dry_run: false)
        Person.transaction do
          PROBLEMS.each(&:fix!)
          fail "dry run" if dry_run
        end
      end
    end
  end
end
