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
    validate :assert_adult_household_people_mitglieder_count
  end

  private

  # Returns the number of adult family mitglieder in the household including the current person.
  def adult_household_people_mitglieder_count
    person.
      household_people.
      flat_map(&:roles).
      select do |role|
      # We only care about Mitglied roles
      role.is_a?(SacCas::Role::Mitglied) &&
        # We only care about family beitragskategorie roles
        role.beitragskategorie&.familie? &&
        # Make sure the person has a birthday before we compare the years
        role.person.birthday? &&
        AGE_RANGE_ADULT.cover?(role.person.years)
    end.
      map(&:person_id). # A person might have multiple Mitglied roles, count one per person.
      uniq.
      count
  end

  # There can only be MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT adults with beitragskategory=family
  # in a household.
  def assert_adult_household_people_mitglieder_count
    # We do not need to validate this if the current role has a beitragskategorie other than family
    # or if the person of the current role is not an adult.
    return unless beitragskategorie&.familie? && AGE_RANGE_ADULT.cover?(person.years)

    # Including current person, we can not have more than MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT adults.
    return unless adult_household_people_mitglieder_count + 1 > MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT

    errors.add(:base, :too_many_adults_in_family, max_adults: MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT)
  end

end
