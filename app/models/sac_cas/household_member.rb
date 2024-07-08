# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::HouseholdMember
  extend ActiveSupport::Concern

  prepended do
    validate :assert_email, on: :destroy
    validate :assert_planned_termination, on: :destroy
  end

  def assert_email
    if person.email.blank?
      errors.add(:base, :no_email, person_name: person.full_name)
    end
  end

  def assert_planned_termination
    if Group::SektionsMitglieder::Mitglied.where(person_id: person.id)
        .where(terminated: true).exists?
      errors.add(:base, :planned_termination, person_name: person.full_name)
    end
  end
end
