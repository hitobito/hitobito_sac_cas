# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Events::FiltersController do
  render_views

  let(:user) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before do
    sign_in(user)
  end

  describe "GET #new" do
    it "renders filter form with tour essentials" do
      get :new, params: {
        group_id: group.id,
        type: "Event::Tour",
        year: 2023,
        filters: {
          sac: {season: "summer"},
          tour_essentials: {discipline_id: [event_disciplines(:wandern).id]},
          approval: {self_approved: "true", responsible_komitee_id: groups(:bluemlisalp_freigabekomitee).id}
        }
      }

      expect(response).to have_http_status(:ok)

      expect(dom).to have_content("Saison")
      expect(dom).to have_checked_field("filters_sac_season_summer")
      expect(dom).to have_content("Subito")

      expect(dom).to have_selector(".accordion-button", text: "Felder")

      expect(dom).to have_selector(".accordion-button", text: "Freigabe")
      expect(dom).to have_checked_field("Selbst freigegeben")
      expect(dom).to have_select("Zuständiges Freigabe-Komitee", selected: "Freigabekomitee")

      expect(dom).to have_selector(".accordion-button", text: "Wesentliche Fakten")
    end
  end

  describe "POST #create" do
    it "redirects to list" do
      post :create,
        params: {
          group_id: group.id,
          type: "Event::Tour",
          year: 2023,
          range: "group",
          filters: {sac: {subito: "false"},
                    tour_essentials: {discipline_id: [event_disciplines(:wandern).id], target_group_id: [""]},
                    approval: {self_approved: "1", responsible_komitee_id: groups(:bluemlisalp_freigabekomitee).id}}
        }

      expect(response).to redirect_to(tour_group_events_path(
        group,
        year: 2023,
        range: "group",
        filters: {sac: {subito: "false"},
                  tour_essentials: {discipline_id: [event_disciplines(:wandern).id.to_s]},
                  approval: {self_approved: "1", responsible_komitee_id: groups(:bluemlisalp_freigabekomitee).id.to_s}}
      ))
    end
  end
end
