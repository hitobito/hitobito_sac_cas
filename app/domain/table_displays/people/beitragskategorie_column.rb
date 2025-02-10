# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class BeitragskategorieColumn < TableDisplays::Column
    def required_model_attrs(attr)
      ["roles.beitragskategorie"]
    end

    def render(attr)
      super do |person|
        beitragskategorie(target)
      end
    end

    def required_permission(attr)
      :show_full
    end

    private

    def allowed_value_for(target, target_attr, &block)
      beitragskategorie(target)
    end

    def beitragskategorie(person)
      person.roles.collect(&:beitragskategorie).compact.sort.uniq.collect do |value|
        I18n.t(value, scope: "roles.beitragskategorie")
      end.join(", ").presence
    end
  end
end
