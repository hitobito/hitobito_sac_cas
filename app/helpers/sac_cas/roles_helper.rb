# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::RolesHelper
  def format_role_membership_years(role)
    f(role.membership_years.floor) if role.is_a?(Group::SektionsMitglieder::Mitglied)
  end

  def terminate_role_link(role)
    return Roles::UndoTerminateRoleLink.new(role, self).render if role.terminated?

    buttons = [Roles::ChangeZusatzsektionToFamilyLink.new(role, self).render, super]
    content_tag(:div, class: "btn-group", role: "group") { buttons.compact.reduce(:+) }
  end
end
