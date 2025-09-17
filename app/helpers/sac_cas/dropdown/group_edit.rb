# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Dropdown::GroupEdit
  def initialize(template, group)
    super
    if group.root? && template.can?(:index, SacMembershipConfig)
      add_item(translate(:sac_membership_configs),
        template.group_sac_membership_configs_path(
          group_id: Group.root_id
        ))
    end

    if sac_section_or_ortsgruppe? &&
        template.can?(:index, SacSectionMembershipConfig)
      add_item(translate(:sac_section_membership_configs),
        template.group_sac_section_membership_configs_path(
          group_id: group.id
        ))
    end
  end

  private

  def sac_section_or_ortsgruppe?
    group_types = SacSectionMembershipConfig.group_types
    group_types.one? { |t| group.is_a?(t) }
  end
end
