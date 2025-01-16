# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class WiedereintrittColumn < TableDisplays::Column
    def required_model_attrs(attr)
      [:confirmed_at]
    end

    def render(attr)
      super do |person|
        membership_roles = Role.where(type: SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name), person_id: person.id)
        template.f(!membership_roles.exists? && membership_roles.ended.exists?)
      end
    end

    def required_permission(attr)
      :show
    end
  end
end
