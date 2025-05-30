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
    validate :assert_removed_member_email, on: :update
    validate :assert_adult_member_with_email, on: :update
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
        create_missing_people_managers

        if maintain_sac_family?
          update_main_person!(new_household:)
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

  # Sets the reference_person as the main person of the family.
  def set_family_main_person!(person = reference_person)
    update_main_person!(person)
    reload
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
    # main person must be processed first
    with_main, without_main = new_people.partition(&:sac_family_main_person)
    (with_main + without_main).each do |p|
      Memberships::FamilyMutation.new(p.reload).join!(reference_person)
    end
    removed_people.each { |p| Memberships::FamilyMutation.new(p.reload).leave! }
  end

  def update_main_person!(person = nil, new_household: false)
    raise "invalid main person" if person && people.exclude?(person)
    new_main_person = person ||
      main_person ||
      reference_person_as_main_in_new_household(new_household) ||
      oldest_person # may be nil when destroying
    others = people - [new_main_person]

    ActiveRecord::Base.transaction do
      (others + removed_people).select(&:sac_family_main_person).each do |person|
        person.update!(sac_family_main_person: false)
      end
      new_main_person&.update!(sac_family_main_person: true)
    end
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

  def assert_removed_member_email
    return if removed_people.all?(&:email?)

    errors.add(:base, :removed_member_has_no_email)
  end

  def assert_adult_member_with_email
    return if adults.any? { _1.email? }

    errors.add(:base, :no_adult_member_with_email)
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

  def adults = people_by_agegroup(:adult)

  def validate_members
    # do not validate members for sac imports
    return unless @validate_members
    super
  end
end
