module Wizards
  module Steps
    class ChooseSektion < ::WizardStep
      attribute :group_id, :integer

      validates :group_id, presence: true

      def groups
        Group.where(type: [Group::Sektion.sti_name, Group::Ortsgruppe.sti_name])
      end

      def group
        @group ||= Group.find(group_id) if group_id.present?
      end

    end
  end
end
