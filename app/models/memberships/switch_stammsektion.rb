# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class SwitchStammsektion < JoinBase
    def initialize(...)
      super
      raise "terminated membership" if sac_membership.stammsektion_role&.terminated?
    end

    private

    def prepare_roles(person)
      previous_stammsektion_role = People::SacMembership.new(person).stammsektion_role
      mark_for_termination(previous_stammsektion_role) if previous_stammsektion_role

      new_stammsektion_role = build_role(
        membership_group,
        Group::SektionsMitglieder::Mitglied.sti_name,
        person,
        previous_stammsektion_role&.beitragskategorie || calculate_beitrags_kategorie(person),
        previous_stammsektion_role&.end_on_was
      )

      roles = [previous_stammsektion_role, new_stammsektion_role]
      roles += yield(previous_stammsektion_role) if block_given?
      roles.compact
    end

    def mark_for_termination(role)
      if role.start_on.today?
        role.mark_for_destruction
        if role.is_a?(Group::SektionsMitglieder::Mitglied)
          role.skip_destroy_dependent_roles = true
          role.skip_destroy_household = true
        end
      else
        role.end_on = now.to_date - 1.day
      end
    end

    def build_role(group, type, person, beitragskategorie, end_on)
      group.roles.build({
        type:,
        person:,
        # `Role#set_beitragskategorie` gets called in a before_validation callback, but
        # `Memberships::CommonApi#validate_roles` and `Memberships::CommonApi#save_roles`
        # first save the roles with `validate: false` to make the role validations working which
        # depend on persisted values. So we need to set the beitragskategorie here manually.
        beitragskategorie:,
        start_on: now.to_date,
        end_on: end_on || now.to_date.end_of_year
      })
    end

    def validate_family_main_person?
      person.sac_membership.family?
    end

    def membership_group
      @membership_group ||= join_section.children.find_by(type: Group::SektionsMitglieder.sti_name)
    end

    def calculate_beitrags_kategorie(person)
      SacCas::Beitragskategorie::Calculator.new(person).calculate
    end
  end
end
