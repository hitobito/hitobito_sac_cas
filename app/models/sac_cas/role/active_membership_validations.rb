# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Role::ActiveMembershipValidations
  extend ActiveSupport::Concern

  MITGLIED_ROLES = [Group::SektionsMitglieder::Mitglied,
    Group::SektionsMitglieder::MitgliedZusatzsektion]

  included do
    validate :assert_has_active_membership_role
  end

  def assert_has_active_membership_role
    unless Role.with_inactive.exists?(type: MITGLIED_ROLES.map(&:sti_name),
      person_id: person_id,
      group_id: group_id)
      errors.add(:person, :must_have_mitglied_role_in_group)
    end
  end
end
