# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Roles
  class UndoTerminateRoleLink
    delegate :can?, :link_to, :button_tag, :content_tag, :t, to: :@view

    def initialize(role, view)
      @role = role
      @view = view
    end

    def render
      return unless @role.terminated? &&
        role.is_a?(SacCas::Role::MitgliedCommon) &&
        # TODO: only render link if terminated role is the latest role in the role.group
        can?(:create, UndoTermination)

      link_to(t("roles/terminations.global.undo"),
        @view.new_group_role_undo_termination_path(role_id: @role.id,
          group_id: @role.group_id,
          person_id: @role.person_id),
        class: "btn btn-sm btn-outline-primary",
        remote: true)
    end
  end
end
