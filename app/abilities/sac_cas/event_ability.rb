# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::EventAbility
  extend ActiveSupport::Concern
  include SacCas::AbilityDsl::Constraints::Event

  prepended do
    on(Event) do
      permission(:any)
        .may(:manage_attachments, :index_full_participations)
        .for_participations_full_events

      permission(:group_full).may(:index_full_participations).in_same_group
      permission(:group_full).may(:create_tags).none
      permission(:group_and_below_full).may(:index_full_participations).in_same_group_or_below
      permission(:group_and_below_full).may(:create_tags).none
      permission(:layer_full).may(:index_full_participations).in_same_layer
      permission(:layer_and_below_full).may(:index_full_participations).in_same_layer_or_below

      permission(:layer_events_full)
        .may(:index_participations, :index_full_participations, :qualifications_read, :show)
        .in_same_layer_group
      permission(:layer_events_full)
        .may(:create, :update, :destroy, :application_market, :qualify,
          :create_tags, :assign_tags, :manage_attachments)
        .in_same_layer_group_if_active

      permission(:layer_created_events_full)
        .may(:create)
        .in_tourenleiter_sektion

      permission(:layer_created_events_full)
        .may(:update, :assign_tags, :manage_attachments)
        .in_tourenleiter_sektion_for_own
    end

    on(Event::Tour) do
      class_side(:list_available).everybody
    end
  end

  def in_tourenleiter_sektion
    tourenleiter_sektion_ids = user.roles.select do |r|
      [Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation,
        Group::SektionsTourenUndKurse::Tourenleiter].include?(r.class)
    end.map { |r| r.group.layer_group_id }

    tourenleiter_sektion_ids.include?(subject.groups.first.id)
  end

  def in_tourenleiter_sektion_for_own
    in_tourenleiter_sektion && subject.creator_id == user.id
  end
end
