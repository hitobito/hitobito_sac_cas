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

          expect(assigns(:events)).to match_array(events(:top_course, :application_closed))
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

      it "does not display certain fields in state review" do
        get :edit, params: params

        expect(dom).not_to have_text "Ist Subito-Tour"
        expect(dom).not_to have_text "Disziplin(en)"
        expect(dom).not_to have_text "Zielgruppe(n)"
        expect(dom).not_to have_text "Konditionelle Anforderung"
        expect(dom).not_to have_text "Technische Anforderung(en)"
        expect(dom).not_to have_text "Saison"
      end

      it "does display all fields in state draft" do
        event.update!(state: :draft)

        get :edit, params: params

        expect(dom).to have_text "Ist Subito-Tour"
        expect(dom).to have_text "Disziplin(en)"
        expect(dom).to have_text "Zielgruppe(n)"
        expect(dom).to have_text "Konditionelle Anforderung"
        expect(dom).to have_text "Technische Anforderung(en)"
        expect(dom).to have_text "Saison"
      end
    end

    describe "PUT#update" do
      it "renders warning flash when date is changed in state review" do
        post :update, params: {
          group_id: group.id,
          id: event.id,
          event: {
            dates_attributes: {
              "1" => {id: event.dates.first.id,
                      start_at_date: "24.05.2021",
                      finish_at_date: "17.02.2026"}
            }
          }
        }
        expect(flash[:notice]).to be_nil
        expect(flash[:warning]).to eq "Tour Bundstock wurde erfolgreich aktualisiert. Stelle bitte sicher, " \
          "dass du die geänderten von- und bis-Daten mit deiner Tourenkommission abgestimmt hast."
      end

      it "does not render warning flash when date is not changed" do
        post :update, params: {
          group_id: group.id,
          id: event.id,
          event: {
            name: "anothername"
          }
        }
        expect(flash[:warning]).to be_nil
      end

      it "does not render warning flash when state is draft" do
        event.update!(state: :draft)

        post :update, params: {
          group_id: group.id,
          id: event.id,
          event: {
            dates_attributes: {
              "1" => {id: event.dates.first.id,
                      start_at_date: "24.05.2021",
                      finish_at_date: "17.02.2026"}
            }
          }
        }

        expect(flash[:warning]).to be_nil
      end
    end
  end
end
