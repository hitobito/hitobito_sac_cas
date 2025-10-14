# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Person::SubscriptionsController
  extend ActiveSupport::Concern

  private

  def subscribed
    @subscribed ||= grouped_by_layer(subscriptions_without_fundraising)
  end

  def subscriptions_without_fundraising
    # rubocop:todo Layout/LineLength
    subscriptions.subscribed.where.not(internal_key: SacCas::MAILING_LIST_SPENDENAUFRUFE_INTERNAL_KEY)
    # rubocop:enable Layout/LineLength
  end
end
