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
      permission(:group_and_below_full).may(:show, :index_subscriptions).schreibrecht_in_same_group?
      permission(:group_and_below_full).may(:create, :update, :destroy).schreibrecht_in_same_group?
      permission(:group_and_below_full)
        .may(:export_subscriptions)
        .schreibrecht_in_same_group?
    end
  end

  def schreibrecht_in_same_group?
    in_same_group_or_below && role_type?(Group::SektionsMitglieder::Schreibrecht)
  end
end
