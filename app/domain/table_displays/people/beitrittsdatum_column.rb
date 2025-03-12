# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class BeitrittsdatumColumn < TableDisplays::Column
    prepend TableDisplays::People::SektionMemberAdminVisible

    def render(attr)
      super do |person|
        beitrittsdatum(person)
      end
    end

    def required_permission(attr)
      :show
    end

    private

    def allowed_value_for(target, target_attr, &block)
      beitrittsdatum(target)
    end

    def beitrittsdatum(person)
      start_on = person.roles
        .select { |r| SacCas::MITGLIED_ROLES.include?(r.type.constantize) }
        .select { |r| hierarchy.cover?(r.group.lft) && hierarchy.cover?(r.group.rgt) }
        .collect(&:start_on)
        .compact.min
      I18n.l(start_on) if start_on
    end

    def hierarchy = (template.parent.lft..template.parent.rgt)
  end
end
