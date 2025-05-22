# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Roles
  class ChangeZusatzsektionToFamilyLink
    delegate :can?, :link_to, :icon, :t, :safe_join, :params, to: :@view

    def initialize(role, view)
      @role = role
      @view = view
    end

    def render
      return unless render?

      link_to(safe_join([icon(:"exchange-alt"), t("roles/change_zusatzsektion_to_family.link")], " "),
        @view.group_person_role_change_zusatzsektion_to_family_path(role_id: @role.id,
          group_id: params[:group_id],
          person_id: @role.person_id),
        class: "btn btn-sm btn-outline-primary",
        method: :post)
    end

    private

    def render?
      can?(:manage, Memberships::ChangeZusatzsektionToFamily) &&
        @role.is_a?(Group::SektionsMitglieder::MitgliedZusatzsektion) &&
        @role.active? &&
        @role.beitragskategorie != "family" &&
        @role.person.sac_membership.family? &&
        @role.person.sac_family_main_person?
    end
  end
end
