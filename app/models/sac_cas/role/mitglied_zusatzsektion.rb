# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Role::MitgliedZusatzsektion
  extend ActiveSupport::Concern

  include SacCas::Role::MitgliedCommon

  included do
    validate :assert_is_mitglied_during_validity_period, on: [:create, :update]
  end

  def assert_is_mitglied_during_validity_period
    # only validate if both dates are set (otherwise the role will be invalid anyway)
    return unless start_on && end_on

    errors.add(:person, :must_have_mitglied_role) if days_without_stammsektion_membership?
  end

  def days_without_stammsektion_membership?
    memberships = Group::SektionsMitglieder::Mitglied.with_inactive.where(person_id:)

    memberships.reduce(active_period.to_a) do |days, mitglied_role|
      days.reject { |day| mitglied_role.active_period.cover?(day) }
    end.present?
  end
end
