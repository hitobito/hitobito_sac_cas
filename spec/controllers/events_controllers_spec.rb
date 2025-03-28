# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe EventsController do
  let(:person) { people(:admin) }

  before { sign_in(person) }
  before { travel_to(Time.zone.local(2023, 4, 1)) }

  render_views
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  context "course" do
    let(:group) { groups(:root) }
    let(:top_course) { events(:top_course) }

    describe "GET#index" do
      let(:params) { {group_id: group.id, type: "Event::Course"} }

      context "with permission" do
        before do
          top_course.update!(unconfirmed_count: 2)
        end

        it "renders unconfirmed column" do
          get :index, params: params.merge(sort: :number)

          expect(assigns(:events)).to match_array(events(:top_course, :closed))
          expect(dom).to have_css "th a", text: "Unbestätigt"
          expect(dom).to have_css "tr:nth-of-type(1) .badge.bg-secondary"
          expect(dom).not_to have_css "tr:nth-of-type(2) .badge.bg-secondary", text: "2"
        end

        it "sorts by unconfirmed" do
          get :index, params: params.merge(sort: :unconfirmed_count, sort_dir: :desc)

          expect(dom).to have_css "tr:nth-of-type(1) .badge.bg-secondary", text: "2"
          expect(dom).not_to have_css "tr:nth-of-type(2) .badge.bg-secondary"
        end
      end

      context "without permission" do
        let(:person) { people(:mitglied) }

        it "does not render unconfirmed column" do
          get :index, params: params
          expect(dom).not_to have_css "th a", text: "Unbestätigt"
        end
      end
    end

    describe "GET#show" do
      let(:params) { {group_id: group.id, id: top_course.id} }

      it "displays info page" do
        get :show, params: params

        expect(dom).to have_css("h1", text: top_course.name)
      end
    end

    describe "GET#edit" do
      let(:params) { {group_id: group.id, id: top_course.id} }

      it "displays form with tabs" do
        get :edit, params: params

        expect(dom).to have_css("h1", text: top_course.name)
        expect(dom.all("li.nav-item a").map(&:text))
          .to eq(["Allgemein", "Daten", "Anmeldung", "Preise",
            "Kommunikation", "Anmeldeangaben", "Administrationsangaben"])
      end
    end
  end

  context "tour" do
    let(:group) { groups(:bluemlisalp) }
    let(:event) { events(:section_tour) }

    describe "GET#index" do
      let(:params) { {group_id: group.id, type: "Event::Tour"} }

      it "does not render number column" do
        get :index, params: params

        expect(assigns(:events)).to match_array(events(:section_tour))
        expect(dom).not_to have_css "th a", text: "Nummer"
      end
    end

    describe "GET#show" do
      let(:params) { {group_id: group.id, id: event.id} }

      it "displays info page" do
        get :show, params: params

        expect(dom).to have_css("h1", text: event.name)
      end
    end

    describe "GET#edit" do
      let(:params) { {group_id: group.id, id: event.id} }

      it "displays form with tabs" do
        get :edit, params: params

        expect(dom).to have_css("h1", text: event.name)
        expect(dom.all("li.nav-item a").map(&:text))
          .to eq(["Allgemein", "Daten", "Anmeldung", "Anmeldeangaben", "Administrationsangaben"])
      end
    end
  end
end
