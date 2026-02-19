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

      permission(:any)
        .may(:update)
        .for_assigned_freigabe_komitee
    end
  end

  def for_assigned_freigabe_komitee
    user.roles
      .where(type: Group::FreigabeKomitee::Pruefer.sti_name)
      .where(group_id: assigned_freigabe_komitee_ids)
      .exists?
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

  private

  def assigned_freigabe_komitee_ids
    Event::ApprovalCommissionResponsibility
      .where(discipline_id: find_main(:disciplines))
      .where(target_group_id: find_main(:target_groups))
      .where(sektion_id: relevant_group_ids)
      .where(subito: subject.subito)
      .distinct
      .pluck(:freigabe_komitee_id)
  end

  def find_main(assoc)
    subject.send(assoc).select("COALESCE(parent_id, id)")
  end

  # Identifies all groups responsible for commission approval.
  # Includes groups directly associated with the event (Sektion and Ortsgruppe)
  # and inherits responsibilities from the parent Sektion if the event is at the Ortsgruppe level.
  def relevant_group_ids
    subject.groups.pluck(:id, :parent_id).flatten
  end
end
