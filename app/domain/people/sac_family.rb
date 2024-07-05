# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::SacFamily
  delegate :household_key, to: "@person"

  def initialize(person)
    @person = person
  end

  # def create(stammsektion)
  # end

  # trigger after:
  # - adding a new person to household
  # - adding a new child (managed)
  # - adding a manager to a child (manager)
  def update!
    # do nothing unless we find a family membership in the household
    return unless family_stammsektion

    non_family_housemates.each { |new_family_member| update_membership!(new_family_member) }
  end

  def update_terminated_roles
    terminated_roles = @person
      .roles
      .where(type: terminatable_member_role_types,
        terminated: true,
        beitragskategorie: :family)

    affected_family_roles = Role
      .where(type: terminatable_member_role_types,
        group_id: terminated_roles.collect(&:group_id),
        terminated: false,
        beitragskategorie: :family,
        person_id: family_members.collect(&:id))

    delete_on = terminated_roles.first.delete_on
    Roles::Termination.terminate(affected_family_roles, delete_on)
  end

  # def change_stammsektion
  # end

  # def add_zusatzsektion
  # end

  # make sure all family members are approved at the same time
  # def approve_neuanmeldungen
  # end

  def member?
    household_key.present? &&
      @person.roles.where(beitragskategorie: :family).exists?
  end

  def id
    return unless member?

    household_key.start_with?("F") ? household_key : "F#{household_key}"
  end

  # Returns all people in the household that have a family membership.
  # The current @person does not have to be part of the family membership.
  def family_members
    family_stammsektion.people
      .distinct
      .joins(:roles)
      .where(roles: {type: stammsektion_role_types, beitragskategorie: :family},
        people: {household_key: @person.household_key})
  end

  def adult_family_members
    family_members.select { |person| category_calculator(person).adult? }
  end

  def housemates
    @person.household_people + [@person]
  end

  def non_family_housemates
    housemates - family_members
  end

  def main_person
    family_members.find(&:sac_family_main_person)
  end

  def set_family_main_person!
    ActiveRecord::Base.transaction do
      family_members.where(sac_family_main_person: true)
        .update_all(sac_family_main_person: false)
      @person.update!(sac_family_main_person: true)
    end
  end

  private

  def update_membership!(new_family_member)
    calculator = category_calculator(new_family_member)

    # Only children and adults can join a family membership, but not babies and youth
    return unless calculator.family_age?

    # A family can not have more than 2 adults.
    # Additional adults can be in the household, but won't get a family membership.
    return if calculator.adult? && adult_family_members.size >= 2

    # Do nothing if the person already has any membership related role.
    return if new_family_member.roles.where(type: all_member_and_neuanmeldung_role_types).exists?

    add_stammsektion_role(new_family_member)
    add_zusatzsektion_roles(new_family_member)
  end

  def add_stammsektion_role(new_family_member)
    add_role_for_person(new_family_member, family_stammsektion_role)
  end

  def add_zusatzsektion_roles(new_family_member)
    family_member_role_scope(type: zusatzsektion_role_types)
      .index_by(&:group_id)
      .each do |_, role|
      add_role_for_person(new_family_member, role)
    end
  end

  # Duplicate the existing role and assign the person.
  def add_role_for_person(person, role)
    role.dup.tap do |r|
      r.person = person
      r.created_at = Time.current
    end.save!
  end

  def family_stammsektion
    family_stammsektion_role&.group
  end

  # Returns the first stammsektion role of any family member found
  def family_stammsektion_role
    @family_stammsektion_role ||=
      family_member_role_scope(type: stammsektion_role_types).first
  end

  def family_member_role_scope(type:)
    Role.where(
      person: housemates,
      beitragskategorie: :family,
      type: type
    )
  end

  # def update_children
  # add all children to household
  # add all mitglieder roles with Beitragskategorie family to children
  # end

  # def update_adults
  # is there adults in same household that are allowed to get mitglied family roles?
  # end

  def stammsektion_role_types
    SacCas::STAMMSEKTION_ROLES.map(&:sti_name)
  end

  def zusatzsektion_role_types
    SacCas::ZUSATZSEKTION_ROLES.map(&:sti_name)
  end

  def all_member_and_neuanmeldung_role_types
    (SacCas::MITGLIED_ROLES + SacCas::NEUANMELDUNG_ROLES).map(&:sti_name)
  end

  def terminatable_member_role_types
    SacCas::MITGLIED_ROLES.select(&:terminatable).map(&:sti_name)
  end

  def category_calculator(person)
    SacCas::Beitragskategorie::Calculator.new(person)
  end
end
