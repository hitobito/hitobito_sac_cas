# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::JsonApi::EventsController
  extend ActiveSupport::Concern

  WEBSITE_TOKEN = "[Hitobito-Typo3]"
  EXPIRES_IN = 3.hours

  def index
    authorize!(:list_available, Event)
    data = Rails.cache.fetch(dynamic_cache_key, expires_in: EXPIRES_IN) do
      resource_class.all(params).to_jsonapi
    end
    render plain: data, content_type: Mime[:jsonapi]
  end

  private

  def dynamic_cache_key
    maxima = [Event, Event::Participation].map { |model| model.maximum(:updated_at).to_i }

    query = params.to_h.except(:controller, :action, :format).to_query
    [controller_name, action_name, current_ability.identifier, *maxima, query].join("-")
  end
end
