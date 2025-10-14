# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Roles
  class UndoTerminateRoleLink
    delegate :can?, :link_to, :button_tag, :content_tag, :icon, :t, :safe_join, :params, to: :@view

    def initialize(role, view)
      @role = role
      @view = view
    end

    def render
      return unless @role.terminated? &&
        SacCas::MITGLIED_ROLES.include?(@role.class) &&
        latest_role_in_group? &&
        can?(:create, Memberships::UndoTermination)

      link_to(safe_join([icon(:undo), t("roles/terminations.global.undo")], " "),
        @view.new_group_person_role_undo_termination_path(role_id: @role.id,
          # rubocop:todo Layout/LineLength
          group_id: params[:group_id], # ansonsten wird man bei einer Person ohne Rollen auf die Gruppe der damaligen Mitgliedsrolle redirected. Dadurch werden dann die anderen Personenlinks (Info, Bemerkungen, etc.) mit der falschen group id gebaut und es entsteht ein 404
          # rubocop:enable Layout/LineLength
          person_id: @role.person_id),
        class: "btn btn-sm btn-outline-primary")
    end

    def latest_role_in_group?
      Role.with_inactive.where(group: @role.group,
        person: @role.person).reorder(end_on: :desc).first.id == @role.id
    end
  end
end
