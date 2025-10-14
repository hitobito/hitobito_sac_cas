# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Dropdown
  class People::Memberships < Base
    attr_reader :person, :template

    WIZARDS = [
      [Wizards::Memberships::JoinZusatzsektion, :group_person_join_zusatzsektion_path],
      [Wizards::Memberships::SwitchStammsektion, :group_person_switch_stammsektion_path],
      [Wizards::Memberships::SwapStammZusatzsektion, :group_person_switch_stammsektion_path,
        {kind: :zusatzsektion}],
      [Wizards::Memberships::TerminateSacMembershipWizard,
        :group_person_terminate_sac_membership_path]
    ].freeze

    delegate :current_ability, :current_user, :group_person_join_zusatzsektion_path,
      # rubocop:todo Layout/LineLength
      :group_person_terminate_sac_membership_path, :group_person_switch_stammsektion_path, to: :template
    # rubocop:enable Layout/LineLength

    def initialize(template, person, group)
      @template = template
      @person = person
      @group = group
      super(template, translate(:title), :edit)
      init_items
    end

    def to_s
      super if items.present?
    end

    private

    def init_items
      WIZARDS.each do |wizard_class, path, params|
        add_wizard(wizard_class, path, params) if current_ability.can?(:create, build(wizard_class))
      end
      add_undo_termination_link if current_ability.can?(:create, ::Memberships::UndoTermination)
    end

    def add_wizard(wizard_class, path, params)
      wizard_name = wizard_class.to_s.demodulize.to_s.underscore
      target_url = send(path, params.to_h.merge(group_id: @group.id, person_id: @person.id))
      link_name = translate("#{wizard_name}_link")
      add_item(link_name, target_url, method: :get)
    end

    def add_undo_termination_link # rubocop:todo Metrics/AbcSize
      latest_membership = person.sac_membership.stammsektion_role ||
        person.sac_membership.latest_stammsektion_role
      return unless latest_membership&.terminated?

      add_item(translate("undo_termination_link"),
        # rubocop:todo Layout/LineLength
        template.new_group_person_role_undo_termination_path(role_id: person.sac_membership.latest_stammsektion_role.id,
          # rubocop:enable Layout/LineLength
          group_id: person.sac_membership.latest_stammsektion_role.group_id,
          person_id: person.id))
    end

    def build(wizard_class)
      wizard_class.new(
        person: @person,
        backoffice: current_user.backoffice?
      )
    end
  end
end
