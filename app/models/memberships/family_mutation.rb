# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  # This class should be used after a person has been added to or removed from a household
  # and is responsible for updating the roles of a person accordingly.
  class FamilyMutation
    attr_reader :person

    delegate :sac_membership, to: :person

    def initialize(person)
      @person = person
    end

    # Call this method after a person has been added to a household. The household_key must already
    # be set on the person. The method will:
    # * Replace stammsektion role with corresponding family role.
    # * Replace all zusatzsektion roles that have a corresponding role in the
    #   reference_zusatzsektion_roles.
    # * Create missing zusatzsektion roles from reference_zusatzsektion_roles.
    def join!(reference_person)
      raise_if_terminated(sac_membership.stammsektion_role,
        reference_person.sac_membership.stammsektion_role)

      join_stammsektion!(reference_person)
      join_zusatzsektion!(reference_person)
    end

    # Replace all family membership roles with corresponding adult/youth roles
    def leave!
      raise_if_terminated(sac_membership.stammsektion_role)

      beitragskategorie = SacCas::Beitragskategorie::Calculator
        .new(person).calculate(for_sac_family: false)

      if sac_membership.stammsektion_role
        replace_role!(sac_membership.stammsektion_role, beitragskategorie:)
      end
      sac_membership.zusatzsektion_roles.family.each { replace_role!(_1, beitragskategorie:) }
      sac_membership.neuanmeldung_zusatzsektion_roles.family.each { end_role(_1) }
    end

    private

    def join_stammsektion!(reference_person)
      if sac_membership.stammsektion_role
        replace_role!(sac_membership.stammsektion_role,
          reference_person.sac_membership.stammsektion_role)
      else
        create_role!(person,
          reference_person.sac_membership.stammsektion_role)
      end
    end

    def join_zusatzsektion!(reference_person)
      reference_person.sac_membership.zusatzsektion_roles.family.each do |role|
        if (conflicting_role = find_zusatzsektion_role(role.group.layer_group_id))
          replace_role!(conflicting_role, role)
        else
          create_role!(person, role)
        end
      end
    end

    def category_family = SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY

    def replaced_role_end_on = Date.current.yesterday

    def new_role_start_on = Date.current

    # Replace the role with the blueprint role in the same group. The new role is created with a
    # created_at timestamp at the beginning of the current day, but not before the created_at
    # timestamp of the blueprint role.
    # The old role is ended with a deleted_at timestamp at the end of the previous day.
    def replace_role!(role, blueprint_role = role, beitragskategorie: category_family)
      raise "cannot replace with future role" if blueprint_role.start_on.future?

      # terminate old role, skip validations as it might be a family membership which
      # is not valid anymore as the person just left the household
      end_role(role)

      # create new role with beitragskategorie
      create_role!(role.person,
        blueprint_role, beitragskategorie:)
    end

    # Create a new role in the same group as the blueprint role with a created_at timestamp at the
    # beginning of the current day, but not before the created_at timestamp of the blueprint role.
    def create_role!(person, blueprint_role, beitragskategorie: nil)
      blueprint_role.class.create!(
        person:,
        beitragskategorie:,
        group: blueprint_role.group,
        start_on: new_role_start_on,
        end_on: blueprint_role.end_on
      )
    end

    def end_role(role)
      if role.start_on >= Date.current
        role.really_destroy!
      else
        Role.where(id: role.id).update_all(end_on: replaced_role_end_on)
      end
    end

    def find_zusatzsektion_role(layer_group_id)
      sac_membership.zusatzsektion_roles.joins(:group).find_by(group: {layer_group_id:})
    end

    def raise_if_terminated(*roles)
      raise "not allowed with terminated sac membership" if roles.compact.any?(&:terminated?)
    end
  end
end
