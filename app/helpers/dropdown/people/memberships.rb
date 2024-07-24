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
      [Wizards::Memberships::TerminateSacMembershipWizard, :group_person_terminate_sac_membership_path]
    ].freeze

    delegate :t, :current_ability, :current_user, :group_person_join_zusatzsektion_path,
      :group_person_terminate_sac_membership_path, :group_person_switch_stammsektion_path, to: :template

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
      WIZARDS.each do |wizard_class, path|
        add_wizard(wizard_class, path) if current_ability.can?(:create, build(wizard_class))
      end
    end

    def add_wizard(wizard_class, path)
      wizard_name = wizard_class.to_s.demodulize.to_s.underscore
      target_url = send(path, group_id: @group.id, person_id: @person.id)
      add_item(translate("#{wizard_name}_link"), target_url, method: :get)
    end

    def build(wizard_class)
      wizard_class.new(
        person: @person,
        backoffice: current_user.backoffice?
      )
    end

    def t(key)
      I18n.t(key, scope: "dropdowns.memberships")
    end
  end
end
