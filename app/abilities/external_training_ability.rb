# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalTrainingAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Person

  on(ExternalTraining) do
    permission(:layer_full).may(:create, :destroy).in_same_layer
    permission(:layer_and_below_full).may(:create, :destroy).in_same_layer_or_below_if_section_may_create

    permission(:group_full).may(:create, :destroy).in_same_group_if_section_may_create
    permission(:group_and_below_full).may(:create, :destroy).in_same_group_or_below_if_section_may_create
  end

  def person
    subject.person
  end

  def in_same_layer_or_below_unless_sektions_mitgliederverwaltung
    without_role(Group::SektionsFunktionaere::Mitgliederverwaltung) do
      in_same_layer_or_below
    end
  end

  def in_same_layer_if_section_may_create
    in_same_layer && permisson_on_root_or_section_may_create(:layer_full)
  end

  def in_same_layer_or_below_unless_sektions_mitgliederverwaltung_if_section_may_create
    in_same_layer_or_below_unless_sektions_mitgliederverwaltung && permisson_on_root_or_section_may_create(:layer_and_below_full)
  end

  def in_same_group_if_section_may_create
    in_same_group && permisson_on_root_or_section_may_create(:group_full)
  end

  def in_same_group_or_below_if_section_may_create
    in_same_group_or_below && permisson_on_root_or_section_may_create(:group_and_below_full)
  end

  def permisson_on_root_or_section_may_create(permission)
    permitted_groups = user.groups_with_permission(permission)
    user_context.layer_ids(permitted_groups).include?(Group.root.id) ||
      subject.event_kind.section_may_create?
  end
end
