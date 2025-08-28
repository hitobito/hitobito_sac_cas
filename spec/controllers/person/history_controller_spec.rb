# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person::HistoryController do
  render_views

  let(:body) { Capybara::Node::Simple.new(response.body) }
  let(:user) { people(:admin) }
  let(:participation) { event_participations(:top_mitglied) }

  before { sign_in(user) }

  context "GET#index" do
    it "renders actual days for participation" do
      participation.event.update!(training_days: 4)
      participation.update!(actual_days: 2.5)

      get :index, params: {group_id: participation.person.groups.first.id, id: participation.participant_id}

      quali = body.find("tr#event_participation_#{participation.id} td:last-child")
      expect(quali.text.strip).to eq("2.5 Ausbildungstage")
    end
  end
end
