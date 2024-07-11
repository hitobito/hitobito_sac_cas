# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Role::MitgliedFamilyValidations
  extend ActiveSupport::Concern

  MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT = 2
  AGE_RANGE_ADULT = SacCas::Beitragskategorie::Calculator::AGE_RANGE_ADULT

  included do
    # Explicitely run validation on create and update. This allows us to skip this validation
    # on a case by case basis by setting the context to something other than :create or :update.
    # This is used by the memberships_importer and the selfreg workflow to skip these validations.
    with_options(on: [:create, :update]) do
      validate :assert_adult_family_mitglieder_count
      validate :assert_single_family_main_person
    end
  end

  private

  # Returns all family mitglieder from DB including the current person even if it is not persisted yet.
  def family_mitglieder
    people = Household.new(person).people
    people << person unless people.include?(person)
    people
  end

  def adult_family_mitglieder_count
    family_mitglieder
      .count { |family_mitglied| AGE_RANGE_ADULT.cover?(family_mitglied.years) }
  end

  # There can only be MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT adults with beitragskategory=family
  # in a household.
  def assert_adult_family_mitglieder_count
    # We do not need to validate this if the current role has a beitragskategorie other than family
    # or if the person of the current role is not an adult.
    return unless beitragskategorie&.family? && AGE_RANGE_ADULT.cover?(person.years)

    # Including current person, we can not have more than MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT adults.
    return unless adult_family_mitglieder_count > MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT

    errors.add(:base, :too_many_adults_in_family, max_adults: MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT)
  end

  def assert_single_family_main_person
    # We can only validate this if the person is persisted as we use Person#household_key to look up
    # the other family members.
    return unless person.persisted?

    # We do not need to validate this if the current role has a beitragskategorie other than family.
    return unless beitragskategorie&.family?

    # We skip if we are deleted or scheduled to delete as other members will probably be gone.
    return if terminated?

    return if family_mitglieder.count(&:sac_family_main_person) == 1
    errors.add(:base, :must_have_one_family_main_person_in_family)
  end
end
