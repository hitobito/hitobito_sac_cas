# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Person::SubscriptionsController
  extend ActiveSupport::Concern

  private

  def subscribed
    @subscribed ||= subscriptions.subscribed.where(
      "internal_key IS NULL OR internal_key != ?",
      SacCas::MAILING_LIST_SPENDENAUFRUFE_INTERNAL_KEY
    ).includes(group: :layer_group).list.to_a
  end
end
