# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class AntragFuerColumn < TableDisplays::Column
    def render(attr)
      super do |person|
        antrag_fuer(person)
      end
    end

    def required_permission(attr)
      :show
    end

    def exclude_attr?(group)
      [Group::SektionsNeuanmeldungenSektion, Group::SektionsNeuanmeldungenNv].exclude?(group.class)
    end

    private

    def allowed_value_for(target, target_attr, &block)
      antrag_fuer(target)
    end

    def antrag_fuer(person) # rubocop:todo Metrics/CyclomaticComplexity
      group_roles = person.roles.select { |r| r.group_id == template&.parent&.id }
      if group_roles.any? { |r| SacCas::NEUANMELDUNG_ZUSATZSEKTION_ROLES.include?(r.class) }
        I18n.t("groups.sektion_secondary")
      elsif group_roles.any? { |r| SacCas::NEUANMELDUNG_STAMMSEKTION_ROLES.include?(r.class) }
        I18n.t("groups.sektion_primary")
      end
    end
  end
end
