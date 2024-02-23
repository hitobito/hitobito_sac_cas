# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Person::Household
  extend ActiveSupport::Concern

  HOUSEHOLD_KEY_SEQUENCE = 'person.household_key'

  delegate :adult?, :child?, to: :beitragskategorie_calculator

  def assign
    super

    assign_children if adult?
    assign_parents if child?
    self
  end

  def remove
    Person.transaction do
      super

      person.manageds.clear
      person.managers.clear
    end
  end

  def save
    Person.transaction do
      managers_changed =
        person.people_managers.any?(&:changed?) ||
        person.people_manageds.any?(&:changed?)

      super

      if managers_changed
        person.people_managers.each(&:save!)
        person.people_manageds.each(&:save!)
      end
    end
  end

  private

  # Add all children in the household to the adult person's "Elternzugang".
  def assign_children
    housemates_by_agegroup(:child).each do |child|
      next unless ability.can?(:update, child)

      person.people_manageds.include?(child) || person.people_manageds.build(managed: child)
    end
  end

  # Add the child person to the "Elternzugang" of all parents in the household.
  def assign_parents
    housemates_by_agegroup(:adult).each do |adult|
      next unless ability.can?(:update, adult)

      adult.people_managers.include?(person) || person.people_managers.build(manager: adult)
    end
  end

  # Find all people in the household that are in the given age category.
  # @param [Symbol] age_category One of :adult, :child
  def housemates_by_agegroup(age_category)
    raise ArgumentError, "Invalid age category #{age_category}" unless
      %i[adult child].include?(age_category)

    housemates.select do |other_person|
      SacCas::Beitragskategorie::Calculator.new(other_person).send("#{age_category}?")
    end
  end

  def beitragskategorie_calculator
    @beitragskategorie_calculator ||= SacCas::Beitragskategorie::Calculator.new(person)
  end

  def next_key
    "#{Sequence.increment!(HOUSEHOLD_KEY_SEQUENCE)}"
  end
end
