# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  module SektionMemberAdminVisible
    # Allow Sektions Admin to view tables even though person no longer
    # has an active role in that sektion
    #
    # Since https://github.com/hitobito/hitobito/commit/80aa972cd6f8f26342d0318099b034c592462145
    # this could in theory also be achieved using standard ability checks (as ended roles are taken
    # into account) but as Group::SektionsFunktionaere::Mitgliederverwaltung has no permissions at
    # all we stick with this solution

    # this required_model_includes could be removed if we relied solely on our abilities
    def required_model_includes(_attr)
      # rubocop:todo Layout/LineLength
      super + ((@model_class == Person) ? [roles_unscoped: :group] : [])
      # rubocop:enable Layout/LineLength
    end

    private

    def allowed?(object, attr, _original_object, _original_attr)
      super || (section_admin_layer_ids & object_membership_layer_ids(object)).any?
    end

    def object_membership_layer_ids(object)
      roles_unscoped(object).select do |role|
        SacCas::MITGLIED_ROLES.include?(role.class)
      end.map { |role| role.group.layer_group_id }
    end

    def section_admin_layer_ids
      ability.user.roles.includes(:group).select do |role|
        SacCas::SAC_SECTION_MEMBER_ADMIN_ROLE_TYPES.include?(role.class)
      end.map { |role| role.group.layer_group_id }
    end

    def roles_unscoped(object)
      case object
      when Person then object.roles_unscoped
      when Event::Participation then object.participant.roles_unscoped
      else []
      end
    end
  end
end
