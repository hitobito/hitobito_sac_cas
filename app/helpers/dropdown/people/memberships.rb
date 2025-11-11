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
        {kind: :zusatzsektion}]
    ].freeze

    delegate :current_ability, :current_user, :group_person_join_zusatzsektion_path,
      :group_person_terminate_sac_membership_path, :group_person_switch_stammsektion_path,
      to: :template

    delegate :can?, to: :current_ability
    delegate :sac_membership, to: "@person"

    def initialize(template, person, group)
      @template = template
      @person = person
      @group = group
      @stammsektion = person.sac_membership.stammsektion
      super(template, translate(:title), :edit)
      init_items
    end

    def to_s
      super if items.present?
    end

    private

    def init_items
      WIZARDS.each do |wizard_class, path, params|
        add_wizard(wizard_class, path, params) if can?(:create, build(wizard_class))
      end
      add_terminate_sac_membership_link if can?(:terminate, sac_membership.stammsektion_role)
      add_undo_termination_link if can?(:create, ::Memberships::UndoTermination)
    end

    def add_wizard(wizard_class, path, params)
      wizard_name = wizard_class.to_s.demodulize.to_s.underscore
      target_url = send(path, params.to_h.merge(group_id: @group.id, person_id: @person.id))
      link_name = translate("#{wizard_name}_link")
      add_item(link_name, target_url, method: :get)
    end

    def add_undo_termination_link # rubocop:todo Metrics/AbcSize
      latest_membership = sac_membership.stammsektion_role ||
        sac_membership.latest_stammsektion_role
      return unless latest_membership&.terminated?

      add_item(translate(:undo_termination_link),
        template.new_group_person_role_undo_termination_path(
          role_id: latest_membership.id,
          group_id: latest_membership.group_id,
          person_id: person.id
        ))
    end

    def add_terminate_sac_membership_link
      return unless sac_membership.active?
      return if current_user == person &&
        sac_membership.stammsektion.mitglied_termination_by_section_only

      add_item(
        translate(:terminate_sac_membership_link),
        group_person_terminate_sac_membership_path(
          group_id: sac_membership.stammsektion.id,
          person_id: person.id
        )
      )
    end

    def build(wizard_class)
      wizard_class.new(
        person: @person,
        backoffice: current_user.backoffice?,
        current_ability: current_ability
      )
    end
  end
end
