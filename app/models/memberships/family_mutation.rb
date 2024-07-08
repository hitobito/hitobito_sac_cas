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
      join_future_stammsektion!(reference_person)
      join_zusatzsektion!(reference_person)
      # currently there is no such thing as future zusatzsektion roles, so we can stop here
    end

    # Replace all family membership roles with corresponding adult/youth roles
    def leave!
      raise_if_terminated(sac_membership.stammsektion_role)

      beitragskategorie = SacCas::Beitragskategorie::Calculator
        .new(person).calculate(for_sac_family: false)
      replace_role!(sac_membership.stammsektion_role, beitragskategorie:)
      sac_membership.future_stammsektion_roles.each { replace_role!(_1, beitragskategorie:) }
      sac_membership.zusatzsektion_roles.family.each { replace_role!(_1, beitragskategorie:) }
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

    def join_future_stammsektion!(reference_person)
      sac_membership.future_stammsektion_roles.each(&:destroy!)
      reference_person.sac_membership.future_stammsektion_roles.each do |role|
        create_role!(person, role)
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

    def replaced_role_deleted_at = Time.current.yesterday.end_of_day

    def new_role_created_at = Time.current.beginning_of_day

    # Replace the role with the blueprint role in the same group. The new role is created with a
    # created_at timestamp at the beginning of the current day, but not before the created_at
    # timestamp of the blueprint role.
    # The old role is ended with a deleted_at timestamp at the end of the previous day.
    def replace_role!(role, blueprint_role = role, beitragskategorie: category_family)
      # terminate old role, skip validations as it might be a family membership which
      # is not valid anymore as the person just left the household
      Role.where(id: role.id).update_all(deleted_at: replaced_role_deleted_at, delete_on: nil)

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
        created_at: new_role_created_at,
        delete_on: blueprint_role.delete_on,
        convert_on: blueprint_role.convert_on,
        convert_to: blueprint_role.convert_to
      )
    end

    def find_zusatzsektion_role(layer_group_id)
      sac_membership.zusatzsektion_roles.joins(:group).find_by(group: {layer_group_id:})
    end

    def raise_if_terminated(*roles)
      raise "not allowed with terminated sac membership" if roles.compact.any?(&:terminated?)
    end
  end
end
