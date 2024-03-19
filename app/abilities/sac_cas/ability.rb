# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Ability

  private

  def define_root_abilities
    super
    prevent_changes_to_newsletter_mailing_list
  end

  def define_user_abilities(...)
    super
    prevent_changes_to_newsletter_mailing_list
  end

  def prevent_changes_to_newsletter_mailing_list
    with_options(internal_key: SacCas::NEWSLETTER_MAILING_LIST_INTERNAL_KEY) do
      cannot [:destroy], MailingList
      cannot [:update], MailingList, [:subscribable_for, :subscribable_mode, :filter_chain]
    end
    cannot [:update, :destroy], Subscription, mailing_list: {
      internal_key: SacCas::NEWSLETTER_MAILING_LIST_INTERNAL_KEY
    }
    cannot [:update], Group, [:sac_newsletter_mailing_list_id]
  end

end
