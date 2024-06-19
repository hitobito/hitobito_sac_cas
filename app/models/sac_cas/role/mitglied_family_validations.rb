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

  # Returns all family mitglieder including the current person.
  def family_mitglieder
    people = person.
             household_people.
             joins(:roles).
             merge(Role.where(type: SacCas::MITGLIED_HAUPTSEKTION_ROLES,
                              beitragskategorie: :family)).to_a

    people << person
  end

  def adult_family_mitglieder_count
    family_mitglieder.
      select { |family_mitglied| AGE_RANGE_ADULT.cover?(family_mitglied.years) }.
      size
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
    # We do not need to validate this if the current role has a beitragskategorie other than family.
    return unless beitragskategorie&.family?

    return if family_mitglieder.count(&:sac_family_main_person) == 1

    errors.add(:base, :must_have_one_family_main_person_in_family)
  end

end
