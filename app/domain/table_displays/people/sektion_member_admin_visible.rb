# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  module SektionMemberAdminVisible
    # Allow Sektions Admin to view tables even though person no longer
    # has an active role in that sektion
    def required_model_includes(_attr)
      super + [roles_unscoped: :group]
    end

    private

    def allowed?(object, attr, _original_object, _original_attr)
      super || (section_admin_layer_ids & object_membership_layer_ids(object)).any?
    end

    def object_membership_layer_ids(object)
      object.roles_unscoped.select do |role|
        SacCas::MITGLIED_ROLES.include?(role.class)
      end.map { |role| role.group.layer_group_id }
    end

    def section_admin_layer_ids
      ability.user.roles.includes(:group).select do |role|
        SacCas::SAC_SECTION_MEMBER_ADMIN_ROLE_TYPES.include?(role.class)
      end.map { |role| role.group.layer_group_id }
    end
  end
end
