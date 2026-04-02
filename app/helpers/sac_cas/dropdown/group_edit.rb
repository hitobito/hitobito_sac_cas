# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Dropdown::GroupEdit
  def setting_items
    super

    sac_membership_config_item if group.root? && template.can?(:index, SacMembershipConfig)
    sac_section_membership_config_item if sac_section_or_ortsgruppe? &&
      template.can?(:index, SacSectionMembershipConfig)
    event_approval_commission_responsibility_item if edit_approval_commission_responsibilities?
  end

  private

  def sac_membership_config_item
    add_item(translate(:sac_membership_configs),
      template.group_sac_membership_configs_path(
        group_id: Group.root_id
      ))
  end

  def sac_section_membership_config_item
    add_item(translate(:sac_section_membership_configs),
      template.group_sac_section_membership_configs_path(group))
  end

  def event_approval_commission_responsibility_item
    add_item(translate(:event_approval_commission_responsibility),
      template.edit_group_event_approval_commission_responsibilities_path(group))
  end

  def sac_section_or_ortsgruppe?
    group_types = SacSectionMembershipConfig.group_types
    group_types.one? { |t| group.is_a?(t) }
  end

  def edit_approval_commission_responsibilities?
    template.can?(:update,
      group) && group.event_types.include?(::Event::Tour) && group.tours_enabled
  end
end
