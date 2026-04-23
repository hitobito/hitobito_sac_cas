# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Groups
  class InitSacSectionCustomContentsJob < BaseJob
    GROUP_TYPES = [Group::Sektion, Group::Ortsgruppe].map(&:sti_name)

    self.parameters = [:group_id]

    attr_reader :group_id

    def initialize(group = nil)
      super()
      @group_id = group&.id
    end

    def perform
      if group_id
        group = Group.find(group_id)
        CustomContent.init_section_specific_contents(group)
      else
        Group.where(type: GROUP_TYPES).find_each(batch_size: 10) do |group|
          CustomContent.init_section_specific_contents(group)
        end
      end
    end
  end
end
