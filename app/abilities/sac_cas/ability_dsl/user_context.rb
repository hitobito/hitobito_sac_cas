# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::AbilityDsl
  module UserContext
    extend ActiveSupport::Concern

    # Configuration mapping a "trigger" permission to a set of permissions that should be
    # granted for groups of a specific class sharing the same layer_group.
    SAME_LAYER_RELATED_GROUPS_PERMISSIONS = {
      layer_mitglieder_full: {group_and_below_full: Group::SektionsMitglieder},
      layer_touren_und_kurse_full: {group_and_below_full: Group::SektionsTourenUndKurse}
    }.freeze

    private

    def init_groups
      super
      grant_permissions_for_same_layer_related_groups
    end

    def grant_permissions_for_same_layer_related_groups
      SAME_LAYER_RELATED_GROUPS_PERMISSIONS.each do |trigger_permission, permission_configs|
        next unless all_permissions.include?(trigger_permission)

        # Find the layer groups associated with the user's trigger permission.
        layer_group_ids = user.groups_with_permission(trigger_permission).map(&:layer_group_id).uniq
        next if layer_group_ids.empty?

        permission_configs.each do |base_permission_to_grant, related_group_classes|
          all_permissions_to_grant = expand_permission_with_implications(base_permission_to_grant)
          target_group_ids = Group.where(
            type: Array(related_group_classes).map(&:sti_name),
            layer_group_id: layer_group_ids
          ).pluck(:id)

          grant(all_permissions_to_grant, target_group_ids) unless target_group_ids.empty?
        end
      end
    end

    # Expand a single permission to include all its implications.
    def expand_permission_with_implications(base_permissions)
      Role::PermissionImplications.each_with_object(Array(base_permissions)) do |(given, implicated), expanded_permissions|
        expanded_permissions.concat(Array(implicated)) if expanded_permissions.include?(given)
      end.uniq
    end

    def grant(permissions, group_ids)
      permissions.each do |permission|
        self.all_permissions |= [permission]
        @permission_group_ids[permission] |= group_ids
      end
    end
  end
end
