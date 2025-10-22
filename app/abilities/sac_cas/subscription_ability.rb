# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club.
#  This file is part of hitobito_sac_cas and
#  licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::SubscriptionAbility
  extend ActiveSupport::Concern

  prepended do
    on(Subscription) do
      general(:manage).except_protected_lists
    end
  end

  def except_protected_lists
    SacCas::PROTECTED_MAILING_LISTS_INTERNAL_KEYS.exclude?(subject.mailing_list.internal_key)
  end
end
