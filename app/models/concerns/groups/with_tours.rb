# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Groups::WithTours
  extend ActiveSupport::Concern

  included do
    after_save :create_tour_notification_mailing_lists, if: -> { tours_enabled == true }
  end

  private

  def create_tour_notification_mailing_lists
    [
      [::SacCas::MAILING_LIST_REGULAR_TOUR_INTERNAL_KEY,
        "Benachrichtigung bei neuen normalen Tourausschreibungen"],
      [::SacCas::MAILING_LIST_SUBITO_TOUR_INTERNAL_KEY,
        "Benachrichtigung bei neuen Subito-Tourausschreibungen"]
    ].each do |internal_key, name|
      list = MailingList.find_or_create_by(internal_key:,
        group_id: id,
        name:,
        subscribable_for: "configured",
        subscribable_mode: "opt_in")

      sub = Subscription.where(mailing_list_id: list.id, subscriber: self).first_or_initialize
      sub.role_types = SacCas::MITGLIED_ROLES
      sub.save!
    end
  end
end
