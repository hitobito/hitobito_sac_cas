# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club.
#  This file is part of hitobito_sac_cas and
#  licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PersonAbility
  extend ActiveSupport::Concern

  prepended do
    on(Person) do
      class_side(:create_households).if_sac_employee
      permission(:read_all_people).may(:read_all_people, :show).everybody
      permission(:layer_and_below_full)
        .may(:index_invoices, :create_membership_invoice)
        .if_sac_employee
      permission(:any)
        .may(:set_sac_family_main_person)
        .if_person_is_adult_and_all_household_members_writable
      permission(:any).may(:show_remarks).if_employee_or_functionary
      permission(:any).may(:manage_national_office_remark).if_sac_employee
      permission(:any).may(:manage_section_remarks).if_section_functionary
    end

    def if_employee_or_functionary
      if_sac_employee || if_section_functionary
    end

    def if_sac_employee
      SacCas::SAC_MITARBEITER_ROLES.any? { |r| role_type?(r) }
    end

    def if_section_functionary
      SacCas::SAC_SECTION_FUNCTIONARY_ROLES.any? { |r| role_type?(r) }
    end

    def if_person_is_adult_and_all_household_members_writable
      return false if person.household_people.empty?
      return false unless person.adult?

      [person, *person.household_people].all? do |household_person|
        can_update_household_person?(household_person)
      end
    end

    def can_update_household_person?(household_person)
      Ability.new(user).can?(:update, household_person)
    end
  end
end
