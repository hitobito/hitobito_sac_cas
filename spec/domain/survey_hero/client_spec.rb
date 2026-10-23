# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SurveyHero::Client do
  let(:copy_url) { "https://api.surveyhero.com/v1/surveys/2132544/collectors/2013394/copy" }

  subject(:client) { described_class.new }

  before { Settings.survey_hero.config = {user: "user", password: "secret"} }
  after { Settings.survey_hero.config = nil }

  describe "#copy_collector" do
    def copy_collector
      client.copy_collector("2132544", "2013394", name: "SAC Kursumfrage: Skikurs (10)")
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

    it "raises with api error message" do
      stub_request(:post, copy_url).to_return(
        status: 403,
        headers: {content_type: "application/json"},
        body: {error: {code: 40310, message: "No access to survey"}}.to_json
      )

      expect { copy_collector }.to raise_error(RestClient::Forbidden, "No access to survey")
    end

    it "raises when new collector has no link" do
      stub_request(:post, copy_url).to_return(
        headers: {content_type: "application/json"},
        body: {collector_id: 1, email_invite: []}.to_json
      )

      expect { copy_collector }.to raise_error(SurveyHero::Client::Error, /has no survey link/)
    end
  end
end
