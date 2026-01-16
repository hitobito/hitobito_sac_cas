# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Household
  extend ActiveSupport::Concern

  HOUSEHOLD_KEY_SEQUENCE = "household_sequence"

  prepended do
    validate :assert_adult_member, on: :update
    validate :assert_minimum_member_size, on: :update
    validate :assert_someone_is_a_member, on: :update
  end

  def initialize(reference_person, maintain_sac_family: true, validate_members: true)
    super(reference_person)
    @maintain_sac_family = maintain_sac_family
    @validate_members = validate_members
  end

  def save(context: :update, &)
    Person.transaction do
      new_household = new_record? # remember value before persisting
      super do |new_people, removed_people|
        yield new_people, removed_people if block_given?
        clear_people_managers(removed_people)

        if maintain_sac_family?
          new_main_person = determine_new_main_person(new_household:)
          update_main_person!(new_main_person)
          create_missing_people_managers(new_main_person)
          mutate_memberships!(new_people, removed_people)
        end
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

  def set_family_main_person!(person = reference_person)
    raise "invalid main person" if people.exclude?(person)

    Person.transaction do
      update_main_person!(person)
      create_missing_people_managers(person)
    end
    reload
  end

  def main_person
    people.find(&:sac_family_main_person)
  end

  def maintain_sac_family?
    @maintain_sac_family
  end

  def create_missing_people_managers(manager = main_person)
    return if manager.nil?

    change_manageds = people - [manager] - manager.manageds
    clear_people_managers(change_manageds)

    change_manageds.each do |managed|
      PeopleManager.create!(manager:, managed:)
    end
  end

  def adults = people_by_agegroup(:adult)

  private

  def clear_people_managers(people)
    people.each do |person|
      person.manageds.clear
      person.managers.clear
    end
  end

  def mutate_memberships!(new_people, removed_people)
    # main person must be processed first
    sorted = new_people.sort_by { |p| p.sac_family_main_person ? 0 : 1 }
    sorted.each do |p|
      Memberships::FamilyMutation.new(p.reload).join!(reference_person)
    end
    removed_people.each do |p|
      Memberships::FamilyMutation.new(p.reload).leave!
    end
  end

  def update_main_person!(new_main_person)
    others = people - [new_main_person]
    (others + removed_people).select(&:sac_family_main_person).each do |person|
      person.update!(sac_family_main_person: false)
    end
    new_main_person&.update!(sac_family_main_person: true)
  end

  def determine_new_main_person(new_household: false)
    main_person ||
      reference_person_as_main_in_new_household(new_household) ||
      oldest_person # may be nil when destroying
  end

  def next_key
    Sequence.increment!(HOUSEHOLD_KEY_SEQUENCE).to_s
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

  def assert_someone_is_a_member
    someone_is_member = members.any? { |member| member.person.sac_membership_active? }
    unless someone_is_member
      errors.add(:members, :no_members)
    end
  end

  def oldest_person = candidates.max_by(&:years)

  def reference_person_as_main_in_new_household(new_household)
    reference_person if new_household && candidates.include?(reference_person)
  end

  def candidates = adults.select(&:email?)

  def people_by_agegroup(age_category)
    people.select do |person|
      SacCas::Beitragskategorie::Calculator.new(person).send(:"#{age_category}?")
    end
  end

  def validate_members
    # do not validate members for sac imports
    super if @validate_members
  end
end
