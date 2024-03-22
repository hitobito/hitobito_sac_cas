# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Person::Household
  extend ActiveSupport::Concern

  HOUSEHOLD_KEY_SEQUENCE = 'person.household_key'

  delegate :adult?, :child?, to: :beitragskategorie_calculator

  module ClassMethods
    def next_key
      "#{Sequence.increment!(HOUSEHOLD_KEY_SEQUENCE)}"
    end
  end

  def maintain_sac_family? = !!@maintain_sac_family

  def initialize(person, ability, other = nil, user = nil, maintain_sac_family: true)
    @maintain_sac_family = maintain_sac_family
    super(person, ability, other, user)
  end

  def valid?
    [assert_no_conflicting_family_membership, super].all?
  end

  private

  def remove
    Person.transaction do
      super

      person.manageds.clear
      person.managers.clear
    end
  end

  def save
    Person.transaction do
      super

      create_missing_people_managers
      person.sac_family.update! if maintain_sac_family?
    end
  end

  def assert_no_conflicting_family_membership
    return true unless maintain_sac_family?
    return true unless Role.where(person_id: existing_people, beitragskategorie: :familie).exists?

    new_housemates_with_family_membership_role = Role.
      where(person_id: new_people, beitragskategorie: :familie).
      map(&:person).
      uniq

    new_housemates_with_family_membership_role.each do |other|
      person.errors.
        add(:household_people_ids, :conflicting_family_membership, name: "#{other.first_name} #{other.last_name}")
    end
    new_housemates_with_family_membership_role.empty?
  end


  # Add people managers for all missing combinations of adults and children in the household.
  def create_missing_people_managers
    household_adults.each do |adult|
      next if ability.cannot?(:update, adult)

      household_children.each do |child|
        next if ability.cannot?(:update, child)
        next if adult.manageds.include?(child)

        PeopleManager.create!(manager: adult, managed: child)
      end
    end
  end

  # Find all people in the household that are in the given age category.
  # @param [Symbol] age_category One of :adult, :child
  def people_by_agegroup(age_category)
    raise ArgumentError, "Invalid age category #{age_category}" unless
      %i[adult child].include?(age_category)

    people.select do |person|
      SacCas::Beitragskategorie::Calculator.new(person).send("#{age_category}?")
    end
  end

  def household_adults
    people_by_agegroup(:adult)
  end

  def household_children
    people_by_agegroup(:child)
  end

  def beitragskategorie_calculator
    @beitragskategorie_calculator ||= SacCas::Beitragskategorie::Calculator.new(person)
  end

  def next_key
    self.class.next_key
  end
end
