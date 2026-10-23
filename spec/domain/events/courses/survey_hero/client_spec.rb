# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Courses::SurveyHero::Client do
  let(:copy_url) { "https://api.surveyhero.com/v1/surveys/5367281/collectors/8294016/copy" }

  subject(:client) { described_class.new }

  before { Settings.survey_hero.config = {user: "user", password: "secret"} }
  after { Settings.survey_hero.config = nil }

  describe "#copy_collector" do
    def copy_collector
      client.copy_collector("5367281", "8294016", name: "SAC Kursumfrage: Skikurs (10)")
    end

    it "posts name with basic auth and returns link of new collector" do
      request = stub_request(:post, copy_url)
        .with(basic_auth: %w[user secret], body: {name: "SAC Kursumfrage: Skikurs (10)"}.to_json)
        .to_return(
          headers: {content_type: "application/json"},
          body: {collector_id: 1, survey_link: {url: "https://www.umfrageonline.com/c/abc"}}.to_json
        )

      expect(copy_collector).to eq "https://www.umfrageonline.com/c/abc"
      expect(request).to have_been_requested
    end

    def stub_api_error(status, code, message)
      stub_request(:post, copy_url).to_return(
        status:,
        headers: {content_type: "application/json"},
        body: {error: {code:, message:}}.to_json
      )
    end

    it "raises error with keys for unknown survey or collector" do
      stub_api_error(404, 40400, "Resource Not Found")

      expect { copy_collector }.to raise_error(Events::Courses::SurveyHero::Client::Error,
        "Collector 8294016 of survey 5367281: Resource Not Found")
    end

    it "raises error with keys for survey of other account" do
      stub_api_error(403, 40310, "Forbidden: You are not allowed access to this survey")

      expect { copy_collector }.to raise_error(Events::Courses::SurveyHero::Client::Error,
        "Collector 8294016 of survey 5367281: " \
        "Forbidden: You are not allowed access to this survey")
    end

    it "raises rest client error with api error message for technical errors" do
      stub_api_error(429, 42910, "Too Many Requests")

      expect { copy_collector }.to raise_error(RestClient::TooManyRequests, "Too Many Requests")
    end

    it "raises when new collector has no link" do
      stub_request(:post, copy_url).to_return(
        headers: {content_type: "application/json"},
        body: {collector_id: 1, email_invite: []}.to_json
      )

      expect { copy_collector }.to raise_error(Events::Courses::SurveyHero::Client::Error, /has no survey link/)
    end
  end
end
