# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Dropdown
  class People::Memberships < Base
    attr_reader :person, :template

    delegate :t, :current_ability, :current_user, :group_person_join_zusatzsektion_path,
      to: :template

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
      add_join_zusatzsektion_item if join_zusatzsektion?
    end

    def add_join_zusatzsektion_item
      link = group_person_join_zusatzsektion_path(group_id: @group.id, person_id: @person.id)
      add_item(translate(:join_zusatzsektion_link), link, method: :get)
    end

    def join_zusatzsektion?
      current_ability.can?(:create,
        Wizards::Memberships::JoinZusatzsektion.new(person: @person,
          backoffice: current_user.backoffice?))
    end

    def t(key)
      I18n.t(key, scope: "dropdowns.memberships")
    end
  end
end
