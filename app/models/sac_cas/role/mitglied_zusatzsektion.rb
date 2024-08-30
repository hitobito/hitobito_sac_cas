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

    # If the end_on date is present, we can iterate over the active period and check all days.
    # Otherwise we have to check the active period until the start of the open ended membership.
    # Unless there is no open ended membership, in which case it can not be covered.
    check_range = end_on.present? ? active_period : start_on...openended_membership&.start_on

    if check_range.end.present?
      uncovered_days = all_memberships.reduce(check_range.to_a) do |days, mitglied_role|
        days.reject { |day| mitglied_role.active_period.cover?(day) }
      end

      return if uncovered_days.empty?
    end

    errors.add(:person, :must_have_mitglied_role)
  end
end
