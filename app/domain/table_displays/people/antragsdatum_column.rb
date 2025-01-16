# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class AntragsdatumColumn < TableDisplays::Column
    def required_model_attrs(attr)
      ["roles.group_id"]
    end

    def render(attr)
      super do |person|
        created_at = person.roles.select { |r| r.group_id == template&.parent&.id }.collect(&:created_at).min
        I18n.l(created_at.to_date) if created_at
      end
    end

    def required_permission(attr)
      :show
    end

    def exclude_attr?(template)
      [Group::SektionsNeuanmeldungenSektion, Group::SektionsNeuanmeldungenNv].exclude?(template&.parent.class)
    end
  end
end
