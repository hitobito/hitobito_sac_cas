# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Household
  extend ActiveSupport::Concern

  HOUSEHOLD_KEY_SEQUENCE = 'person.household_key'

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
end
