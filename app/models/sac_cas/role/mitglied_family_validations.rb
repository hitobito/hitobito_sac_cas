# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Role::MitgliedFamilyValidations
  extend ActiveSupport::Concern

  MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT = 2

  included do
    validate :assert_adult_family_members_count
    validate :assert_family_on_primary_group
  end

  private

  # There can only be MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT adults with beitragskategory=family in a household.
  def assert_adult_family_members_count
    return unless person&.household_key? &&
      beitragskategorie == SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY.to_s &&
      SacCas::Beitragskategorie::Calculator::AGE_ADULT.cover?(person.years)

    adult_housemates_count = person.
                             household_people.
                             flat_map(&:roles).
                             select do |role|
      # We only care about Mitglied roles
      role.is_a?(SacCas::Role::Mitglied) &&
        # We only care about family beitragskategorie roles
        role.beitragskategorie == SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY.to_s &&
        # Make sure the person has a birthday before we compare the years
        role.person.birthday? &&
        SacCas::Beitragskategorie::Calculator::AGE_ADULT.cover?(role.person.years)
    end.
                             map(&:person_id). # A person might have multiple Mitglied roles, count one per person.
                             uniq.
                             count

    # Including the current person, we can not have more than MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT adults.
    return unless adult_housemates_count + 1 > MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT

    errors.add(:base, :too_many_adults_in_family, max_adults: MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT)
  end

  # Roles with beitragskategorie=family are only allowed on the primary group of a person.
  def assert_family_on_primary_group
    return unless beitragskategorie == SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY.to_s

    unless group == person&.primary_group
      errors.add(:base, :family_role_on_non_primary_group)
    end
  end

end
