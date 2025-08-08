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

    def initialize(prolongation_date, reference_date)
      @prolongation_date = prolongation_date
      @reference_date = reference_date
    end

    def extend_roles
      convert_roles_to_youth
      convert_roles_to_adult

      roles_to_extend.in_batches(of: BATCH_SIZE) do |batch|
        Role.where(id: batch.pluck(:id)).update_all(end_on: @prolongation_date)
      end
    end

    private

    def roles_to_extend
      Role.where(type: ROLES_TO_EXTEND, terminated: false, end_on: ...@prolongation_date, person_id: person_ids)
    end

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
        end_role(role)
        create_mitglied_role(role.person, role.group, :adult)

        role.person.sac_membership.zusatzsektion_roles.where(terminated: false, end_on: ...@prolongation_date, beitragskategorie: :youth).find_each do |zusatzsektion_role|
          end_role(zusatzsektion_role)
          create_zusatzmitglied_role(zusatzsektion_role.person, zusatzsektion_role.group, :adult)
        end
      end
    end

    def leave_household(person)
      Memberships::FamilyMutation.new(person, new_role_end_on: @prolongation_date, new_role_start_on: new_role_start_on, replaced_role_end_on: @reference_date).leave!
    end

    def promote_to_youth(person, group)
      create_mitglied_role(person, group, :youth)

      person.sac_membership.zusatzsektion_roles.where(beitragskategorie: :youth, terminated: false, end_on: ...@prolongation_date).update_all(end_on: @prolongation_date)

      person.sac_membership.zusatzsektion_roles.where(beitragskategorie: :family).find_each do |zusatzsektion_role|
        end_role(zusatzsektion_role)
        create_zusatzmitglied_role(person, zusatzsektion_role.group, :youth)
      end
    end

    def roles_to_turn_youth
      Role.joins(:person).where(type: SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name), terminated: false, end_on: ...@prolongation_date, beitragskategorie: :family, person_id: beitragskategorie_change_relevant_person_ids, person: {birthday: turned_youth_reference_age})
    end

    def roles_to_turn_adult
      Role.joins(:person).where(type: SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name), terminated: false, end_on: ...@prolongation_date, beitragskategorie: :youth, person_id: beitragskategorie_change_relevant_person_ids, person: {birthday: turned_adult_reference_age})
    end

    def beitragskategorie_change_relevant_person_ids
      Person.joins(:roles_unscoped)
        .where(id: person_ids, roles: {end_on: ..@prolongation_date})
        .where.not(roles: {start_on: @reference_date.., end_on: @prolongation_date..})
        .select(:id)
    end

    def person_ids
      Person.joins(:roles_unscoped)
        .where(roles: {type: Group::SektionsMitglieder::Mitglied.sti_name, terminated: false, end_on: ..@prolongation_date})
        .where.not(id: ExternalInvoice::SacMembership.where(year: @prolongation_date.year).select(:person_id))
        .where.not(data_quality: :error)
        .select(:id)
    end

    def create_mitglied_role(person, group, beitragskategorie)
      Group::SektionsMitglieder::Mitglied.create!(person:, group:, beitragskategorie:, start_on: new_role_start_on, end_on: @prolongation_date)
    end

    def create_zusatzmitglied_role(person, group, beitragskategorie)
      Group::SektionsMitglieder::MitgliedZusatzsektion.create!(person:, group:, beitragskategorie:, start_on: new_role_start_on, end_on: @prolongation_date)
    end

    def turned_adult_reference_age = ..(@reference_date - 23.years)

    def turned_youth_reference_age = (@reference_date - 23.years)..(@reference_date - 18.years)

    def new_role_start_on = @reference_date + 1.day

    def end_role(role) = role.update!(end_on: @reference_date)
  end
end
