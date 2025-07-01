# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::RoleAbility
  extend ActiveSupport::Concern

  include SacCas::AbilityDsl::Constraints::Event

  prepended do
    on(::Event::Role) do
      permission(:any).may(:show, :create, :update).for_participations_full_events_except_courses
      permission(:any).may(:destroy).for_participations_full_events_except_courses

      permission(:layer_events_full).may(:manage).in_same_layer_group_if_active
    end
  end

  def for_participations_full_events_except_courses
    for_participations_full_events && !event.course?
  end
end
