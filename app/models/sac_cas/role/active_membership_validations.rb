# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Role::ActiveMembershipValidations
  extend ActiveSupport::Concern

  included do
    validates :start_on, :end_on, presence: true
    validate :assert_has_active_membership_role
  end

  def assert_has_active_membership_role
    # Only validate if both dates are set (otherwise the role will be invalid anyway)
    return unless start_on && end_on

    errors.add(:person, :must_have_mitglied_role_in_group) if days_without_membership?
  end

  def days_without_membership?
    memberships = Role.with_inactive.where(
      type: SacCas::MITGLIED_ROLES.map(&:sti_name),
      person_id:,
      group_id:
    )

    memberships.reduce(active_period.to_a) do |days, mitglied_role|
      days.reject { |day| mitglied_role.active_period.cover?(day) }
    end.present?
  end
end
