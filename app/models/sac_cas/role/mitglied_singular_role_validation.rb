# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Role::MitgliedSingularRoleValidation
  extend ActiveSupport::Concern

  included do
    validate :assert_no_overlapping_mitglied_role, on: [:create, :update]
  end

  def assert_no_overlapping_mitglied_role
    # This validation is only relevant if the role is active right now.
    return unless active_period.cover?(Time.zone.today)

    other_mitglied_roles = Group::SektionsMitglieder::Mitglied.
                           without_archived.
                           where(person_id: person_id).
                           where.not(id: id)

    # This validation is only relevant if the person has any other
    # Mitglied roles that are active right now.
    return unless other_mitglied_roles.any? do |role|
      role.active_period.overlaps?(active_period)
    end

    errors.add(:person, :only_one_mitglied_role_allowed_at_a_time)
  end

end
