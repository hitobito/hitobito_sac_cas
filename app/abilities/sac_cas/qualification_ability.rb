# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::QualificationAbility
  extend ActiveSupport::Concern

  PERMISSION_GIVING_ROLE_TYPES = [
    *SacCas::TOURENCHEF_ROLES,
    Group::SektionsFunktionaere::Administration
  ]

  included do
    prepend SacCas::AbilityDsl::Constraints::MatchingRoles

    on(Qualification) do
      permission(:any).may(:create, :destroy).for_tourenchef_qualification_as_tourenchef_in_layer
      permission(:layer_and_below_full).may(:create, :destroy).permission_in_top_layer
    end
  end

  def for_tourenchef_qualification_as_tourenchef_in_layer
    (subject.qualification_kind.nil? || subject.qualification_kind.tourenchef_may_edit?) &&
      matching_roles_in_same_layer(user_role_types: PERMISSION_GIVING_ROLE_TYPES)
  end

  def permission_in_top_layer
    permission_in_layer?(Group.root.id)
  end
end
