# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People
  module SacMemberships
    class DestroyHouseholdsForInactiveMembershipsJob < RecurringJob
      def next_run
        Time.current.tomorrow.change(hour: 0, min: 8)
      end

      def perform_internal
        affected_family_people.find_each(batch_size: 100) do
          _1.household.destroy
        end
      end

      def affected_family_people
        Person.where.not(household_key: ["", nil])
          .where("id NOT IN (?)", people_with_active_family_roles_ids) # rubocop:disable Rails/WhereNot
          .where(sac_family_main_person: true)
      end

      def people_with_active_family_roles_ids
        Role.select(:person_id).where(
          type: SacCas::STAMMSEKTION_ROLES.map(&:sti_name),
          beitragskategorie: SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY
        )
      end
    end
  end
end
