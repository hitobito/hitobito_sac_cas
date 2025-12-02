# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac

module SacCas::Roles::TerminateRoleLink
  private

  def render_link # rubocop:todo Metrics/CyclomaticComplexity
    if @role.is_a?(Group::SektionsMitglieder::MitgliedZusatzsektion)
      customized_termination_link(:group_person_role_leave_zusatzsektion_path)
    elsif @role.is_a?(Group::SektionsMitglieder::Mitglied)
      customized_termination_link(:group_person_role_terminate_sac_membership_path)
    elsif @role.is_a?(Group::AboMagazin::Abonnent)
      customized_termination_link(:group_person_role_terminate_abo_magazin_abonnent_path)
    else
      super
    end
  end

  def customized_termination_link(path_helper)
    path_args = {role_id: @role.id, group_id: @role.group&.id, person_id: @role.person&.id}

    link_to(
      t("roles/terminations.global.title"),
      @view.send(path_helper, path_args),
      class: "btn btn-sm btn-outline-primary"
    )
  end
end
