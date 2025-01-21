# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class WiedereintrittColumn < TableDisplays::Column
    def required_model_attrs(attr)
      []
    end

    def required_model_includes(attr)
      [:roles_unscoped]
    end

    def render(attr)
      super do |person|
        membership_roles = person.roles_unscoped.select{ |role| SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name).include?(role.type) }
        template.f(!membership_roles.present? && membership_roles.select{ |role| role.ended? }.present?)
      end
    end

    def required_permission(attr)
      :show
    end
  end
end
