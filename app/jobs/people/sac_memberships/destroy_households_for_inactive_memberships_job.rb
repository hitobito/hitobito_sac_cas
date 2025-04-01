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
        affected_family_people.each { _1.household.destroy }
      end

      def affected_family_people
        family_role_types = (SacCas::MITGLIED_STAMMSEKTION_ROLES + SacCas::NEUANMELDUNG_STAMMSEKTION_ROLES).map(&:sti_name)

        people_ids = Role.select(:person_id).where(
          type: family_role_types,
          beitragskategorie: SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY
        )

        Person.where.not(household_key: "")
          .where("id NOT IN (:people_ids)", # rubocop:disable Rails/WhereNot
            people_ids:)
          .distinct_on(:household_key)
      end
    end
  end
end
