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

  # rubocop:todo Metrics/AbcSize
  def assert_is_mitglied_during_validity_period # rubocop:todo Metrics/CyclomaticComplexity # rubocop:todo Metrics/AbcSize
    # validation can be skipped by setting this attribute to truthy
    # This is used by the import as we don't have the complete memberhip history of a person
    # but have to import MitgliedZusatzsektion roles anyway.
    return if try(:skip_mitglied_during_validity_period_validation)

    # to simplify, only validate if both dates are set (otherwise the role will be invalid anyway)
    return unless start_on && end_on

    all_memberships = Group::SektionsMitglieder::Mitglied.with_inactive.where(person_id:)

    # Find open ended membership and check coverage (early return)
    openended_membership = all_memberships.find { !_1.end_on? }
    return if openended_membership.present? && openended_membership.start_on <= start_on

    # Iterate over the active period and check if all days are covered by a membership
    uncovered_days = all_memberships.reduce(active_period.to_a) do |days, mitglied_role|
      days.reject { |day| mitglied_role.active_period.cover?(day) }
    end

    errors.add(:person, :must_have_mitglied_role) if uncovered_days.any?
  end
  # rubocop:enable Metrics/AbcSize
end
