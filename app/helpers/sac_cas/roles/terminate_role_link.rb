# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac

module SacCas::Roles::TerminateRoleLink
  private

  def render_link
    if @role.is_a?(Group::SektionsMitglieder::MitgliedZusatzsektion)
      link_to(t("roles/terminations.global.title"),
        @view.group_person_role_leave_zusatzsektion_path(
          role_id: @role.id, group_id: @role.group&.id, person_id: @role.person&.id
        ),
        class: "btn btn-xs float-right")
    elsif @role.is_a?(Group::SektionsMitglieder::Mitglied)
      link_to(t("roles/terminations.global.title"),
        @view.group_person_terminate_sac_membership_path(
          role_id: @role.id, group_id: @role.group&.id, person_id: @role.person&.id
        ),
        class: "btn btn-xs float-right")
    else
      super
    end
  end
end
