# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::GroupAbility
  extend ActiveSupport::Concern

  prepended do
    on(Group) do
      permission(:any).may(:"index_event/tours").all

      permission(:layer_and_below_read)
        .may(:export_mitglieder)
        .in_same_layer_or_below
      permission(:layer_and_below_full)
        .may(:create_yearly_membership_invoice)
        .if_backoffice

      permission(:layer_read)
        .may(:download_statistics)
        .in_same_layer
      permission(:download_member_statistics)
        .may(:download_statistics)
        .in_same_layer
      permission(:layer_and_below_read)
        .may(:download_statistics)
        .in_same_layer_or_below
    end
  end

  def if_backoffice
    SacCas::SAC_BACKOFFICE_ROLES.any? { |r| role_type?(r) }
  end
end
