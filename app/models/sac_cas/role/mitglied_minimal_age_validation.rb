# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Role::MitgliedMinimalAgeValidation
  extend ActiveSupport::Concern

  MINIMUM_YEARS = SacCas::Beitragskategorie::Calculator::AGE_RANGE_MINOR_FAMILY_MEMBER.begin

  included do
    validate :assert_old_enough, on: [:create, :update]
  end

  private

  def assert_old_enough
    if person&.birthday.nil? || too_young?
      errors.add(:person, :assert_old_enough, minimum_years: MINIMUM_YEARS)
    end
  end

  def too_young?
    person.years < MINIMUM_YEARS
  end
end
