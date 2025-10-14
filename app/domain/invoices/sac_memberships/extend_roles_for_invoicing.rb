# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices::SacMemberships
  class ExtendRolesForInvoicing
    ROLES_TO_EXTEND = (SacCas::MITGLIED_ROLES + [
      Group::Ehrenmitglieder::Ehrenmitglied,
      Group::SektionsMitglieder::Beguenstigt,
      Group::SektionsMitglieder::Ehrenmitglied
    ]).map(&:sti_name)

    BATCH_SIZE = 500

    def initialize(prolongation_date, new_role_start_on)
      @prolongation_date = prolongation_date
      @new_role_start_on = new_role_start_on
      @reference_date = new_role_start_on + 1.year - 1.day
    end

    def extend_roles
      convert_roles_to_youth
      convert_roles_to_adult

      roles_to_extend.in_batches(of: BATCH_SIZE) do |batch|
        Role.with_inactive.where(id: batch.pluck(:id)).update_all(end_on: @prolongation_date)
      end
    end

    private

    def convert_roles_to_youth
      roles_to_turn_youth.includes(:group, :person).find_each do |role|
        if role.person.household.members.count == 2
          role.person.household.people.each { leave_household(_1) }
        else
          leave_household(role.person)
        end
      end
    end

    def convert_roles_to_adult
      roles_to_turn_adult.includes(:person, :group).find_each do |role|
        Role.transaction do
          end_role(role)
          create_mitglied_role(role.person_id, role.group_id, :adult)

          role.person.sac_membership.zusatzsektion_roles.where(terminated: false,
            # rubocop:todo Layout/LineLength
            end_on: ...@prolongation_date, beitragskategorie: :youth).find_each do |zusatzsektion_role|
            # rubocop:enable Layout/LineLength
            end_role(zusatzsektion_role)
            create_zusatzmitglied_role(zusatzsektion_role.person_id, zusatzsektion_role.group_id,
              :adult)
          end
        end
      end
    end

    def leave_household(person)
      Memberships::FamilyMutation.new(person, new_role_end_on: @prolongation_date,
        new_role_start_on: @new_role_start_on, replaced_role_end_on: old_role_end_on).leave!
    end

    def roles_to_turn_youth
      roles_for_beitragskategorie_change(beitragskategorie: :family,
        birthday_range: turned_youth_reference_age)
    end

    def roles_to_turn_adult
      roles_for_beitragskategorie_change(beitragskategorie: :youth,
        birthday_range: turned_adult_reference_age)
    end

    def roles_for_beitragskategorie_change(beitragskategorie:, birthday_range:)
      roles_to_extend.joins(:person).where(
        # rubocop:todo Layout/LineLength
        type: SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name), beitragskategorie:, person: {birthday: birthday_range}
      )
      # rubocop:enable Layout/LineLength
    end

    def roles_to_extend
      Role.with_inactive.where(type: ROLES_TO_EXTEND, terminated: false,
        end_on: old_role_end_on...@prolongation_date, person_id: person_ids)
    end

    def person_ids
      Person.joins(:roles_unscoped)
        .where(roles: {type: Group::SektionsMitglieder::Mitglied.sti_name, terminated: false,
                       end_on: old_role_end_on..@prolongation_date})
        # rubocop:todo Layout/LineLength
        .where.not(id: ExternalInvoice::SacMembership.where(year: @prolongation_date.year).select(:person_id))
        # rubocop:enable Layout/LineLength
        .where.not("people.id IN (?)", Role.with_inactive.where(type: ROLES_TO_EXTEND,
          start_on: @new_role_start_on..).select(:person_id))
        .where.not(data_quality: :error)
        .select(:id)
    end

    def create_mitglied_role(person_id, group_id, beitragskategorie)
      Group::SektionsMitglieder::Mitglied.create!(person_id:, group_id:, beitragskategorie:,
        start_on: @new_role_start_on, end_on: @prolongation_date)
    end

    def create_zusatzmitglied_role(person_id, group_id, beitragskategorie)
      Group::SektionsMitglieder::MitgliedZusatzsektion.create!(person_id:, group_id:,
        beitragskategorie:, start_on: @new_role_start_on, end_on: @prolongation_date)
    end

    def turned_adult_reference_age
      ..(@reference_date - SacCas::Beitragskategorie::Calculator::AGE_RANGE_ADULT.begin.years)
    end

    def turned_youth_reference_age
      first = @reference_date - SacCas::Beitragskategorie::Calculator::AGE_RANGE_YOUTH.end.years
      # rubocop:todo Layout/LineLength
      last = @reference_date - (SacCas::Beitragskategorie::Calculator::AGE_RANGE_MINOR_FAMILY_MEMBER.end + 1).years
      # rubocop:enable Layout/LineLength

      first..last
    end

    def old_role_end_on = @new_role_start_on - 1.day

    def end_role(role) = role.update!(end_on: old_role_end_on)
  end
end
