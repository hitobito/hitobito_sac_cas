# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class DuplicateExistsColumn < TableDisplays::Column
    def required_model_attrs(attr)
      []
    end

    def render(attr)
      super do |person|
        template.f(person.person_duplicates.reject(&:ignore).any?)
      end
    end

    def required_permission(attr)
      :show
    end
  end
end
