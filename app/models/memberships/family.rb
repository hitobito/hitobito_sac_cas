# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class Family
    attr_reader :person

    def initialize(person)
      @person = person
    end

    # * Replace stammsektion role with corresponding family role.
    # * Replace all zusatzsektion roles that have a corresponding role in the reference_zusatzsektion_roles.
    # * Create missing zusatzsektion roles from reference_zusatzsektion_roles.
    def join!(reference_person)
      if membership.stammsektion_role
        replace_role!(membership.stammsektion_role, reference_person.sac_membership.stammsektion_role)
      else
        create_role!(person, reference_person.sac_membership.stammsektion_role)
      end

      # TODO: handle future stammsektion role

      reference_person.sac_membership.zusatzsektion_roles.family.each do |role|
        # TODO: handle future zusatzsektion roles??
        if conflicting_role = find_zusatzsektion_role(role.group.layer_group_id)
          replace_role!(conflicting_role, role)
        else
          create_role!(person, role)
        end
      end
    end

    # Replace all family membership roles with corresponding adult/youth roles
    def leave!
      beitragskategorie = SacCas::Beitragskategorie::Calculator.new(person).calculate(for_sac_family: false)
      replace_role!(membership.stammsektion_role, beitragskategorie: beitragskategorie)
      # TODO: handle future stammsektion role

      person.sac_membership.zusatzsektion_roles.select { |r| r.beitragskategorie&.family? }.each do |role|
        # TODO: handle future zusatzsektion roles??
        replace_role!(role, beitragskategorie:)
      end
    end

    private

    def membership = person.sac_membership

    # Replace the role with the blueprint role in the same group. The new role is created with a created_at timestamp
    # at the beginning of the current day, but not before the created_at timestamp of the blueprint role.
    # The old role is ended with a deleted_at timestamp at the end of the previous day.
    def replace_role!(role, blueprint_role = role, beitragskategorie: nil)
      deleted_at = [
        calculate_created_at(blueprint_role).yesterday.end_of_day,
        role.created_at
      ].max
      delete_on = blueprint_role.delete_on

      # alte Rolle beenden:
      role.update!(deleted_at:, delete_on: nil)

      # neue Rolle erstellen:
      create_role!(role.person, blueprint_role, beitragskategorie:, delete_on:)
    end

    # Create a new role in the same group as the blueprint role with a created_at timestamp at the beginning
    # of the current day, but not before the created_at timestamp of the blueprint role.
    def create_role!(person, blueprint_role, beitragskategorie: nil, created_at: nil, delete_on: nil)
      beitragskategorie ||= SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY
      created_at ||= calculate_created_at(blueprint_role)
      delete_on ||= blueprint_role.delete_on

      blueprint_role.class.create!(
        person:,
        beitragskategorie:,
        group: blueprint_role.group,
        created_at:,
        delete_on:,
        convert_on: blueprint_role.convert_on,
        convert_to: blueprint_role.convert_to
      )
    end

    def calculate_created_at(blueprint_role)
      [Date.current.beginning_of_day, blueprint_role.created_at].max
    end

    def find_zusatzsektion_role(layer_group_id)
      membership.additional_sections_roles.joins(:group).find_by(group: {layer_group_id: layer_group_id})
    end
  end
end
