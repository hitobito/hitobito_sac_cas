# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Dropdown::GroupEdit
  def initialize(template, group)
    super(template, group)
    if group.root? && template.can?(:index, SacMembershipConfig)
      add_item(translate(:sac_membership_configs),
               template.group_sac_membership_configs_path(
                 group_id: Group.root.id))
    end
  end
end
