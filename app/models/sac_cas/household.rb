# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Household
  extend ActiveSupport::Concern

  HOUSEHOLD_KEY_SEQUENCE = 'household_sequence'

  prepended do
    validate :assert_adult_member, on: :update
    validate :assert_minimum_member_size, on: :update
    validate :assert_removed_member_email, on: :update
    validate :assert_adult_member_with_email, on: :update
  end

  def initialize(reference_person, maintain_sac_family: true)
    super(reference_person)
    @maintain_sac_family = maintain_sac_family
  end

  def save(context: :update)
    Person.transaction do
      success = super do |_new_people, removed_people|
        clear_people_managers(removed_people)
        create_missing_people_managers
      end
      reference_person.sac_family.update! if success && maintain_sac_family?

      success
    end
  end

  def destroy
    Person.transaction do
      super do |people|
        clear_people_managers(people)
      end
    end
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
    raise ArgumentError, "Invalid age category #{age_category}" unless
    [:adult, :child].include?(age_category)

    people.select do |person|
      SacCas::Beitragskategorie::Calculator.new(person).send("#{age_category}?")
    end
  end

  def next_key
    Sequence.increment!(HOUSEHOLD_KEY_SEQUENCE).to_s # rubocop:disable Rails/SkipsModelValidations
  end

  def maintain_sac_family?
    @maintain_sac_family
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
    removed_people = Person.where(household_key: household_key)
                           .where.not(id: members.map { _1.person.id })

    if removed_people.any? { _1.email.blank? }
      errors.add(:base, :removed_member_has_no_email)
    end
  end

  def assert_adult_member_with_email
    if adults.none? { _1.email.present? }
      errors.add(:base, :no_adult_member_with_email)
    end
  end

  def adults
    @adults ||= people_by_agegroup(:adult)
  end
end
