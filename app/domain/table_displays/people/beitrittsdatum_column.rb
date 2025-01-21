# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class BeitrittsdatumColumn < TableDisplays::Column
    def required_model_attrs(attr)
      ["roles.group_id"]
    end

    def render(attr)
      super do |person|
        start_on = person.roles.select { |r| r.group_id == template&.parent&.id }.collect(&:start_on).compact.min
        I18n.l(start_on) if start_on
      end
    end

    def required_permission(attr)
      :show
    end
  end
end
