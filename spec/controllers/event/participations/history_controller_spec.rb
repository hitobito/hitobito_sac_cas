# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Participations::HistoryController do
  let(:event) { events(:top_course) }
  let(:group) { event.groups.first }
  let(:participation) { event_participations(:top_mitglied) }
  let(:params) { {group_id: group.id, event_id: event.id, id: participation.id} }

  describe "GET#index" do
    it "as person with show_details permission returns successful response" do
      user = people(:admin)
      expect(Ability.new(user)).to be_able_to(:show_details, participation)

      sign_in(user)

      get :index, params: params
      expect(response).to have_http_status(:success)
    end

    it "as person without permission show_details raises authorization error" do
      user = people(:tourenchef)
      expect(Ability.new(user)).not_to be_able_to(:show_details, participation)

      sign_in(user)

      expect { get :index, params: params }.to raise_error(CanCan::AccessDenied)
    end
  end
end
