# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalTrainingAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Person
  include SacCas::AbilityConstraints

  on(ExternalTraining) do
    permission(:layer_full).may(:create, :destroy).in_same_layer
    permission(:layer_and_below_full).may(:create, :destroy)
      .in_same_layer_or_below_unless_sektions_mitgliederverwaltung

    permission(:group_full).may(:create, :destroy).in_same_group
    permission(:group_and_below_full).may(:create, :destroy).in_same_group_or_below
  end

  def person
    subject.person
  end

  def in_same_layer_or_below_unless_sektions_mitgliederverwaltung
    without_role(Group::SektionsFunktionaere::Mitgliederverwaltung) do
      in_same_layer_or_below
    end
  end
end
