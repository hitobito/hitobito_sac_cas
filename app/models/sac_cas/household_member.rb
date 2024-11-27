# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::HouseholdMember
  extend ActiveSupport::Concern

  prepended do
    validate :assert_planned_termination
  end

  def assert_planned_termination
    if person.sac_membership.terminated?
      errors.add(:base, :planned_termination, person_name: person.full_name)
    end
  end
end
