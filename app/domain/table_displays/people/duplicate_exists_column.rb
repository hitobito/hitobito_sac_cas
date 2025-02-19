# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class DuplicateExistsColumn < TableDisplays::Column
    def render(attr)
      super do |person|
        duplicate_exists(person)
      end
    end

    def required_permission(attr)
      :show
    end

    private

    def allowed_value_for(target, target_attr, &block)
      duplicate_exists(target)
    end

    def duplicate_exists(person)
      person.person_duplicates.reject(&:ignore).any? ? I18n.t(:"global.yes") : I18n.t(:"global.no")
    end
  end
end
