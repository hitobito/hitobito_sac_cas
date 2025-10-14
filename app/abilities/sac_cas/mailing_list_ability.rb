# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club.
#  This file is part of hitobito_sac_cas and
#  licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::MailingListAbility
  extend ActiveSupport::Concern
  include AbilityDsl::Constraints::Group

  prepended do
    on(MailingList) do
      permission(:any)
        .may(:show, :index_subscriptions, :export_subscriptions)
        .read_role_in_layer?
    end
  end

  # Checks if a user has a Schreibrecht for the mailing list in the same main group
  #
  # For example if users are members of SAC Hitobito and have Schreibrecht, they
  # can manage the mailing list of SAC Hitobito.
  def read_role_in_layer?
    user.roles.any? do |r|
      [Group::SektionsFunktionaere::Redaktion,
        Group::SektionsFunktionaere::Mitgliederverwaltung,
        Group::SektionsMitglieder::Leserecht,
        Group::SektionsMitglieder::Schreibrecht].include?(r.class) && r.group.layer_group_id == group.layer_group_id
    end
  end
end
