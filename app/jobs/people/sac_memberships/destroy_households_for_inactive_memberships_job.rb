# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People
  module SacMemberships
    class DestroyHouseholdsForInactiveMembershipsJob < RecurringJob
      def next_run
        Time.current.tomorrow.at_beginning_of_day.change(hour: 0, min: 8).in_time_zone
      end

      def perform_internal
        affected_families.each { _1.household.destroy }
      end

      private

      def affected_families
        family_role_types = (SacCas::MITGLIED_STAMMSEKTION_ROLES + SacCas::NEUANMELDUNG_STAMMSEKTION_ROLES).map(&:sti_name)

        ids = Role.ended.joins(:person).where(type: family_role_types, beitragskategorie: SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY).pluck(:person_id)

        Person.where(id: ids).where.not(household_key: nil).distinct_on(:household_key)
      end
    end
  end
end
