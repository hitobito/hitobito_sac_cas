# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::QualificationAbility
  extend ActiveSupport::Concern

  TOURENCHEF_ROLE_TYPES = [Group::SektionsTourenUndKurseSommer::Tourenchef,
                           Group::SektionsTourenUndKurseWinter::Tourenchef]

  included do
    on(Qualification) do
      permission(:any).may(:create, :destroy).for_tourenchef_qualification_as_tourenchef_in_layer
      permission(:layer_and_below_full).may(:create, :destroy)
        .in_course_layer_or_below_unless_sektions_mitgliederverwaltung
    end
  end

  def in_course_layer_or_below_unless_sektions_mitgliederverwaltung
    without_role(Group::SektionsFunktionaere::Mitgliederverwaltung) do
      in_course_layer_or_below
    end
  end

  def for_tourenchef_qualification_as_tourenchef_in_layer
    (subject.qualification_kind.nil? || subject.qualification_kind.tourenchef_may_edit?) &&
      as_tourenchef_in_layer
  end

  def as_tourenchef_in_layer
    return unless can_show_person?

    contains_any?(tourenchef_layer_group_ids,
      subject.person.layer_group_ids)
  end

  def tourenchef_layer_group_ids
    user.roles.where(type: TOURENCHEF_ROLE_TYPES)
      .includes(:group).collect { _1.group.layer_group_id }.uniq
  end

  def can_show_person?
    Ability.new(user).can?(:show_full, subject.person)
  end
end
