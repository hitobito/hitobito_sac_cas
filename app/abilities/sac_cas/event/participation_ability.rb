# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationAbility
  extend ActiveSupport::Concern

  prepended do
    on(Event::Participation) do
      permission(:any).may(:edit_actual_days).for_participations_full_events

      permission(:any).may(:cancel, :update).her_own
      permission(:any).may(:assign, :summon).none
      permission(:any).may(:absent, :attend).for_participations_full_events

      permission(:group_full).may(:summon).in_same_group
      permission(:layer_and_below_full).may(:summon).in_same_layer

      permission(:layer_and_below_full).may(:leader_settlement).in_same_layer_for_self_employed_leader
      permission(:any).may(:leader_settlement).for_herself_if_self_employed_leader

      general(:summon).if_application
      general(:destroy).unless_her_own
    end
  end

  def unless_her_own
    !her_own
  end

  def in_same_layer_for_self_employed_leader
    in_same_layer && self_employed_leader
  end

  def for_herself_if_self_employed_leader
    her_own && self_employed_leader
  end

  private

  def self_employed_leader
    contains_any?(Event::Course::LEADER_ROLES, participation.roles.select(&:self_employed).map(&:type))
  end
end
