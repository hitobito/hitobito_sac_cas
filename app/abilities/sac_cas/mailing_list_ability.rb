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
      permission(:group_and_below_full)
        .may(:show, :index_subscriptions, :create, :update, :destroy, :export_subscriptions)
        .schreibrecht_in_main_group?
    end
  end

  # Checks if a user has a Schreibrecht for the mailing list in the same main group
  #
  # For example if users are members of SAC Hitobito and have Schreibrecht, they
  # can manage the mailing list of SAC Hitobito.
  def schreibrecht_in_main_group?
    user.roles.any? do |r|
      r.is_a?(Group::SektionsMitglieder::Schreibrecht) && r.group.layer_group_id == group.layer_group_id
    end
  end
end
