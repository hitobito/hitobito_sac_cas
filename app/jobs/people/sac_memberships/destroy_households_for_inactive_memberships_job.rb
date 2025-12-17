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
        destroy_inactive_households
        remove_outgrown_family_members
      end

      def destroy_inactive_households
        iterate_people(sac_family_main_person: true) do |person|
          person.household.destroy
        end
      end

      def remove_outgrown_family_members
        iterate_people(sac_family_main_person: false) do |person|
          Household.new(person, maintain_sac_family: false).remove(person).save!
        end
      end

      def iterate_people(sac_family_main_person:, &block)
        inactive_family_people(sac_family_main_person:).find_each(batch_size: 100) do |person|
          yield person
        rescue => e
          # we obviously have a data inconsistency if this happens. please investigate!
          # notify sentry but continue processing other people
          Sentry.capture_exception(e, extra: {person_id: person.id})
        end
      end

      def inactive_family_people(sac_family_main_person:, &block)
        Person.where.not(household_key: ["", nil])
          .where("id NOT IN (?)", people_with_active_family_roles_ids) # rubocop:disable Rails/WhereNot
          .where(sac_family_main_person:)
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
