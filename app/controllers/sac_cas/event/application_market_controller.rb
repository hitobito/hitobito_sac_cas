# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ApplicationMarketController
  extend ActiveSupport::Concern

  SORT_EXPRESSION = 'event_participations.created_at ASC'.freeze

  def index
    @participants = load_participants.reorder(SORT_EXPRESSION)
    @applications = Event::ParticipationDecorator.decorate_collection(
      load_applications.order(SORT_EXPRESSION)
    )
  end
end
