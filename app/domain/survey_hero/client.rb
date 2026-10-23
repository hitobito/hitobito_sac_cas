# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SurveyHero
  # See https://developer.surveyhero.com/api/
  class Client
    class Error < StandardError; end

    BASE_URL = "https://api.surveyhero.com/v1"

    def copy_collector(survey_key, collector_key, name:)
      collector = post("surveys/#{survey_key}/collectors/#{collector_key}/copy", name:)
      collector.dig("survey_link", "url") ||
        raise(Error, "Collector #{collector["collector_id"]} of survey #{survey_key} " \
                     "has no survey link")
    end

    private

    def post(path, payload)
      response = RestClient::Request.execute(
        method: :post,
        url: "#{BASE_URL}/#{path}",
        payload: payload.to_json,
        user: config[:user],
        password: config[:password],
        headers: {content_type: :json, accept: :json}
      )
      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      e.message = api_error_message(e.response) || e.message
      raise
    end

    def config
      Settings.survey_hero.config
    end

    def api_error_message(response)
      JSON.parse(response.body).dig("error", "message") if response
    rescue JSON::ParserError
      nil
    end
  end
end
