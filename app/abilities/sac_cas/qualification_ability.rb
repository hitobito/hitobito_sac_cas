# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::QualificationAbility
  extend ActiveSupport::Concern

  TOURENCHEF_ROLE_TYPES = [
    Group::SektionsTourenUndKurse::TourenchefSommer,
    Group::SektionsTourenUndKurse::TourenchefWinter,
    Group::SektionsTourenUndKurse::Tourenchef,
    Group::SektionsFunktionaere::Administration
  ].map(&:sti_name)

  included do
    on(Qualification) do
      permission(:any).may(:create, :destroy).for_tourenchef_qualification_as_tourenchef_in_layer
      permission(:layer_and_below_full).may(:create, :destroy).permission_in_top_layer
    end
  end

  def for_tourenchef_qualification_as_tourenchef_in_layer
    (subject.qualification_kind.nil? || subject.qualification_kind.tourenchef_may_edit?) &&
      as_tourenchef_in_layer
  end

  def as_tourenchef_in_layer
    return unless can_show_person?

    contains_any?(tourenchef_layer_group_ids, subject.person.layer_group_ids)
  end

  def tourenchef_layer_group_ids
    user.roles
      .select { |r| TOURENCHEF_ROLE_TYPES.include?(r.class.sti_name) }
      .map { |r| r.group.layer_group_id }
      .uniq
  end

  def permission_in_top_layer
    permission_in_layer?(Group.root_id)
  end

  def can_show_person?
    can_show_full_in_group? || can_show_full_in_layer?
  end

  def can_show_full_in_group?
    contains_any?(
      user_context.permission_group_ids(:group_and_below_full),
      subject.person.local_groups_hierachy_ids
    )
  end

  def can_show_full_in_layer?
    contains_any?(
      user_context.permission_layer_ids(:layer_and_below_full),
      subject.person.groups_hierarchy_ids
    )
  end
end
