# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Ability
  private

  def define_root_abilities
    super
    prevent_changes_to_newsletter_mailing_lists
  end

  def define_user_abilities(...)
    super
    prevent_changes_to_newsletter_mailing_lists
  end

  def prevent_changes_to_newsletter_mailing_lists
    SacCas::PROTECTED_MAILING_LISTS_INTERNAL_KEYS.each do |internal_key|
      with_options(internal_key:) do
        cannot [:destroy], MailingList
        cannot [:update], MailingList, [:subscribable_for, :subscribable_mode, :filter_chain]
      end
      cannot [:manage], Subscription, mailing_list: {
        internal_key:
      }
    end

    cannot [:update], Group, [:sac_newsletter_mailing_list_id]
  end
end
