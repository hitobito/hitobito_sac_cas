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
      old_role = existing_membership(person)

      # In case we can't locate the old membership role, we calculate the beitragskategorie
      # for the person as a fallback value.
      beitragskategorie = old_role&.beitragskategorie ||
        SacCas::Beitragskategorie::Calculator.new(person).calculate
      new_role = new_membership(person, beitragskategorie, old_role.end_on_was)

      [old_role, new_role].compact
    end

    def existing_membership(person)
      People::SacMembership.new(person).stammsektion_role.tap do |role|
        next unless role

        role.end_on = now.to_date - 1.day
      end
    end

    def new_membership(person, beitragskategorie, end_on)
      membership_group.roles.build({
        type: role_type,
        start_on: now,
        end_on:,
        person:,
        # `Role#set_beitragskategorie` gets called in a before_validation callback, but
        # `Memberships::CommonApi#validate_roles` and `Memberships::CommonApi#save_roles`
        # first save the roles with `validate: false` to make the role validations working which
        # depend on persisted values. So we need to set the beitragskategorie here manually.
        beitragskategorie:
      })
    end

    def validate_family_main_person?
      person.sac_membership.family?
    end

    def membership_group
      @membership_group ||= join_section.children.find_by(type: Group::SektionsMitglieder.sti_name)
    end

    def role_type
      Group::SektionsMitglieder::Mitglied
    end
  end
end
