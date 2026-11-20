# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Participations::AttendanceConfirmationsController do
  let(:event) { events(:top_course) }
  let(:group) { event.groups.first }
  let(:participation) { event_participations(:top_mitglied) }
  let(:params) { {group_id: group.id, event_id: event.id, id: participation.id} }

  before do
    event.update_columns(state: "closed")
    participation.update_columns(state: "attended")
  end

  describe "GET#show" do
    it "as participant returns pdf" do
      sign_in(people(:mitglied))

      get :show, params: params

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq "application/pdf"
      expect(response.headers["Content-Disposition"])
        .to include("Teilnahmebestaetigung_Tourenleiter_in_1_Sommer_Edmund_Hillary.pdf")
    end

    it "as person with show_details permission returns pdf" do
      sign_in(people(:admin))

      get :show, params: params

      expect(response).to have_http_status(:success)
    end

    it "as person without show_details permission raises authorization error" do
      user = people(:tourenchef)
      expect(Ability.new(user)).not_to be_able_to(:show_details, participation)
      sign_in(user)

      expect { get :show, params: params }.to raise_error(CanCan::AccessDenied)
    end

    it "raises not found if participation is not attendance confirmable" do
      participation.update_columns(state: "absent")
      sign_in(people(:admin))

      expect { get :show, params: params }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
