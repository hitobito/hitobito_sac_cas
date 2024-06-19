# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards
  module Steps
    class ChooseSektion < Step
      attribute :group_id, :integer
      validates :group_id, presence: true
      validate :assert_group_type, if: :group

      GROUP_TYPES = [Group::Sektion.sti_name, Group::Ortsgruppe.sti_name].freeze

      def groups
        Group
          .where(type: GROUP_TYPES)
          .select(:id, :name)
      end

      def group
        @group ||= Group.find(group_id) if group_id.present?
      end

      private

      def assert_group_type
        if GROUP_TYPES.exclude?(group.type)
          errors.add(:group_id, :invalid)
        end
      end
    end
  end
end
