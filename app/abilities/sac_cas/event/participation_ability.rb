# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationAbility
  extend ActiveSupport::Concern

  prepended do
    on(Event::Participation) do
      permission(:any).may(:cancel).her_own_or_for_participations_full_events

      permission(:any).may(:summon).for_participations_full_events
      permission(:group_full).may(:summon).in_same_group
      permission(:layer_and_below_full).may(:summon).in_same_layer
      general(:summon).if_application
    end
  end
end
