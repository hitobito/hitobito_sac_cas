# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Household
  extend ActiveSupport::Concern

  HOUSEHOLD_KEY_SEQUENCE = "person.household_key"

  prepended do
    validate :assert_adult_member, on: :update
    validate :assert_minimum_member_size, on: :update
    validate :assert_removed_member_email_confirmed, on: :update
    validate :assert_adult_member_with_confirmed_email, on: :update
    validate :assert_someone_is_a_member, on: :update
  end

  def initialize(reference_person, maintain_sac_family: true)
    super(reference_person)
    @maintain_sac_family = maintain_sac_family
  end

  def save(context: :update)
    Person.transaction do
      super do |new_people, removed_people|
        clear_people_managers(removed_people)
        create_missing_people_managers

        if maintain_sac_family?
          update_main_person!
          mutate_memberships!(new_people, removed_people)
        end
      end
    end
  end

  def destroy
    Person.transaction do
      super do |people|
        clear_people_managers(people)
      end
    end
  end

  def reload
    # `#reload` on the base class clears instance variables and re-initializes with
    # the reference person. The `@maintain_sac_family` gets lost so we have to handle this here.
    original_maintain_sac_family = @maintain_sac_family
    super
    @maintain_sac_family = original_maintain_sac_family
    self
  end

  # Sets the reference_person as the main person of the family.
  def set_family_main_person!(person = reference_person)
    ActiveRecord::Base.transaction do
      Person.where(id: people.map(&:id)).where(sac_family_main_person: true)
        .update_all(sac_family_main_person: false)
      person.update!(sac_family_main_person: true)
    end
  end

  def main_person
    people.find(&:sac_family_main_person)
  end

  def maintain_sac_family?
    @maintain_sac_family
  end

  private

  def clear_people_managers(removed_people)
    removed_people.each do |person|
      person.manageds.clear
      person.managers.clear
    end
  end

  def create_missing_people_managers
    adults = people_by_agegroup(:adult)
    children = people_by_agegroup(:child)

    adults.each do |adult|
      children.each do |child|
        next if adult.manageds.include?(child)

        PeopleManager.create!(manager: adult, managed: child)
      end
    end
  end

  # Find all people in the household that are in the given age category.
  # @param [Symbol] age_category One of :adult, :child
  def people_by_agegroup(age_category)
    unless [:adult, :child].include?(age_category)
      raise ArgumentError,
        "Invalid age category #{age_category}"
    end

    people.select do |person|
      SacCas::Beitragskategorie::Calculator.new(person).send(:"#{age_category}?")
    end
  end

  def mutate_memberships!(new_people, removed_people)
    new_people.each { |p| Memberships::FamilyMutation.new(p.reload).join!(reference_person) }
    removed_people.each { |p| Memberships::FamilyMutation.new(p.reload).leave! }
  end

  # Sets one of the adults with confirmed email address as family main person unless
  # there is already exactly one.
  def update_main_person!
    # Take the first main person, or find the first adult with confirmed email
    new_main_person = main_person || people.sort_by(&:years)
      .find { |person| person.adult? && person.confirmed_at? }
    others = people - [new_main_person]
    Person.where(id: others + removed_people).update_all(sac_family_main_person: false)
    Person.where(id: new_main_person).update_all(sac_family_main_person: true)
  end

  def next_key
    Sequence.increment!(HOUSEHOLD_KEY_SEQUENCE).to_s # rubocop:disable Rails/SkipsModelValidations
  end

  def assert_adult_member
    if adults.count.zero?
      errors.add(:base, :at_least_one_adult)
    end

    if adults.count > 2
      errors.add(:base, :not_more_than_two_adults)
    end
  end

  def assert_minimum_member_size
    if members.count < 2
      errors.add(:base, :at_least_two_members)
    end
  end

  def assert_removed_member_email_confirmed
    return if removed_people.all?(&:confirmed_at?)

    errors.add(:base, :removed_member_has_no_email)
  end

  def assert_adult_member_with_confirmed_email
    return if adults.any? { _1.confirmed_at? }

    errors.add(:base, :no_adult_member_with_email)
  end

  def assert_someone_is_a_member
    someone_is_member = members.any? { |member| member.person.sac_membership_active? }
    unless someone_is_member
      errors.add(:members, :no_members)
    end
  end

  def adults
    @adults ||= people_by_agegroup(:adult)
  end
end
