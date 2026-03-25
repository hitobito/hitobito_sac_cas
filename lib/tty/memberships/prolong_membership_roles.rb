# frozen_string_literal: true

#  Copyright (c) 202#, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module Memberships
    class ProlongMembershipRoles
      prepend TTY::Command

      self.description = "Prolong membership and related roles, see HIT-1557"

      # Extension from prior "mini" inkasso runs
      FROM_DATES = [
        Date.parse("31.03.2026"),
        Date.parse("29.03.2026"),
        Date.parse("05.04.2026"),
        Date.parse("12.04.2026"),
        Date.parse("27.04.2026")
      ]
      TO_DATE = Date.new(2026, 5, 1)

      ROLE_TYPES = SacCas::MITGLIED_ROLES + SacCas::MEMBERSHIP_PROLONGABLE_ROLES

      def initialize(from: FROM_DATES, to: TO_DATE)
        @from = from
        @to = to
      end

      def run(dry_run: false)
        Role.transaction do
          roles = Role.where(type: ROLE_TYPES.map(&:sti_name), terminated: false, end_on: @from)
          people_count = roles.count("distinct(person_id)")
          puts "affects #{roles.count} roles and #{people_count} people" # rubocop:disable Rails/Output

          roles.update_all(end_on: @to) unless dry_run
        end
      end
    end
  end
end
