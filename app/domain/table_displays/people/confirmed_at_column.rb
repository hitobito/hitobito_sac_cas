# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class ConfirmedAtColumn < TableDisplays::Column
    def required_model_attrs(attr)
      [:confirmed_at]
    end

    def render(attr)
      super do |person|
        confirmed_at(person)
      end
    end

    def required_permission(attr)
      :show_full
    end

    private

    def allowed_value_for(target, target_attr, &block)
      confirmed_at(target)
    end

    def confirmed_at(person)
      I18n.l(person.confirmed_at.to_date) if person.confirmed_at
    end
  end
end
