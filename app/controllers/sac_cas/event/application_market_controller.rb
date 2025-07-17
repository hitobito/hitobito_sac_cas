# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ApplicationMarketController
  extend ActiveSupport::Concern

  SORT_EXPRESSION = "event_participations.created_at ASC"

  prepended do
    delegate :canceled?, to: :event, prefix: true

    before_action :set_canceled_flash, only: :index, if: :event_canceled?
  end

  def index
    @participants = load_participants.reorder(SORT_EXPRESSION)
    @applications = Event::ParticipationDecorator.decorate_collection(
      load_applications.order(SORT_EXPRESSION)
    )
  end

  private

  def set_canceled_flash = flash.now[:warning] = t(".event_canceled")
end
