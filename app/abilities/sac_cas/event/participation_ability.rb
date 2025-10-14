# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationAbility
  extend ActiveSupport::Concern

  include SacCas::AbilityDsl::Constraints::Event

  prepended do
    on(Event::Participation) do
      permission(:any).may(:update).her_own_or_for_participations_full_events
      permission(:any).may(:update_full).for_participations_full_events

      permission(:any).may(:cancel).her_own
      permission(:any).may(:assign, :summon).none
      permission(:any).may(:absent, :attend).for_participations_full_events
      permission(:any).may(:reactivate).for_leaded_events
      permission(:any).may(:leader_settlement).for_herself_if_self_employed_leader

      permission(:group_full).may(:summon, :update_full).in_same_group

      permission(:group_and_below_full).may(:summon, :update_full).in_same_group_or_below

      permission(:layer_full).may(:summon, :update_full).in_same_layer

      permission(:layer_and_below_full).may(:update_full).in_same_layer_or_below
      permission(:layer_and_below_full).may(:summon).in_same_layer
      permission(:layer_and_below_full).may(:reactivate).in_same_layer_or_below_if_active
      # rubocop:todo Layout/LineLength
      permission(:layer_and_below_full).may(:leader_settlement).in_same_layer_for_self_employed_leader
      # rubocop:enable Layout/LineLength

      permission(:layer_events_full)
        .may(:show, :show_details, :show_full, :print, :create, :update, :destroy, :update_full)
        .in_same_layer_group

      general(:summon).if_application
      general(:destroy).unless_her_own
    end
  end

  def unless_her_own
    !her_own
  end

  def her_own_or_for_participations_full_events
    her_own || for_participations_full_events
  end

  def in_same_layer_for_self_employed_leader
    in_same_layer && self_employed_leader
  end

  def for_herself_if_self_employed_leader
    her_own && self_employed_leader
  end

  private

  def self_employed_leader
    contains_any?(Event::Course::LEADER_ROLES,
      participation.roles.select(&:self_employed).map(&:type))
  end
end
