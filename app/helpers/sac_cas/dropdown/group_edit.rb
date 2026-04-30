# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Dropdown::GroupEdit
  delegate :can?, to: :template

  def setting_items
    super

    custom_content_item
    sac_membership_config_item
    sac_section_membership_config_item
    event_approval_commission_responsibility_item
  end

  private

  def sac_membership_config_item
    return unless group.root? && can?(:index, SacMembershipConfig)

    add_item(translate(:sac_membership_configs),
      template.group_sac_membership_configs_path(
        group_id: Group.root_id
      ))
  end

  def sac_section_membership_config_item
    return unless sac_section_or_ortsgruppe? && can?(:index, SacSectionMembershipConfig)

    add_item(translate(:sac_section_membership_configs),
      template.group_sac_section_membership_configs_path(group))
  end

  def event_approval_commission_responsibility_item
    return unless edit_approval_commission_responsibilities?

    add_item(translate(:event_approval_commission_responsibility),
      template.edit_group_event_approval_commission_responsibilities_path(group))
  end

  def custom_content_item
    return unless sac_section_or_ortsgruppe? && can?(:update, group)

    add_item(translate(:custom_content),
      template.group_sac_section_custom_contents_path(group))
  end

  def sac_section_or_ortsgruppe?
    group_types = SacSectionMembershipConfig.group_types
    group_types.one? { |t| group.is_a?(t) }
  end

  def edit_approval_commission_responsibilities?
    can?(:update, group) &&
      group.event_types.include?(::Event::Tour) &&
      group.tours_enabled
  end
end
