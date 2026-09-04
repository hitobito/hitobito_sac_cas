# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::GroupAbility
  extend ActiveSupport::Concern

  RESTRICTED_GROUPS = [
    Group::SektionsClubhuetten,
    Group::SektionsClubhuette,
    Group::Sektionshuetten,
    Group::Sektionshuette,
    Group::SektionsMitglieder,
    Group::SektionsNeuanmeldungenNv,
    Group::SektionsNeuanmeldungenSektion,
    Group::SektionsFunktionaere,
    Group::Ortsgruppe
  ]

  prepended do
    on(Group) do
      permission(:any).may(:"index_event/tours").all

      permission(:layer_and_below_full)
        .may(:create_yearly_membership_invoice)
        .if_backoffice

      permission(:layer_and_below_read)
        .may(:download_statistics)
        .in_same_layer

      permission(:layer_and_below_full)
        .may(:create)
        .with_parent_in_same_layer_or_below_except_restricted

      permission(:layer_and_below_full)
        .may(:destroy)
        .in_same_layer_or_below_except_permission_giving_or_restricted

      permission(:group_and_below_full)
        .may(:create)
        .with_parent_in_same_group_hierarchy_except_restricted

      permission(:group_and_below_full)
        .may(:destroy)
        .in_below_group_except_restricted
    end
  end

  def if_backoffice
    role_type?(*SacCas::SAC_BACKOFFICE_ROLES)
  end

  def with_parent_in_same_layer_or_below_except_restricted
    with_parent_in_same_layer_or_below && !restricted_sektion_group?
  end

  def with_parent_in_same_group_hierarchy_except_restricted
    with_parent_in_same_group_hierarchy && !restricted_sektion_group?
  end

  def in_same_layer_or_below_except_permission_giving_or_restricted
    in_same_layer_or_below_except_permission_giving && !restricted_sektion_group?
  end

  def in_below_group_except_restricted
    in_below_group && !restricted_sektion_group?
  end

  def restricted_sektion_group?
    !if_backoffice && RESTRICTED_GROUPS.include?(subject.class)
  end
end
