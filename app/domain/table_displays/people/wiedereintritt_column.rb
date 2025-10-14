# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class WiedereintrittColumn < TableDisplays::Column
    prepend TableDisplays::People::SektionMemberAdminVisible

    def required_model_includes(attr)
      [:roles_unscoped]
    end

    def render(attr)
      super do |person|
        wiedereintritt(person)
      end
    end

    def required_permission(attr)
      :show
    end

    private

    def allowed_value_for(target, target_attr, &block)
      wiedereintritt(target)
    end

    def wiedereintritt(person) # rubocop:todo Metrics/CyclomaticComplexity
      membership_roles = person.roles_unscoped.select { |role|
        SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name).include?(role.type)
      }
      # rubocop:todo Layout/LineLength
      (membership_roles.select(&:active?).blank? && membership_roles.select(&:ended?).present?) ? I18n.t(:"global.yes") : I18n.t(:"global.no")
      # rubocop:enable Layout/LineLength
    end
  end
end
