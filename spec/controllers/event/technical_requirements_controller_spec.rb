# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::TechnicalRequirementsController do
  before { sign_in(current_user) }

  let(:current_user) { people(:admin) }
  let(:entry) { event_technical_requirements(:klettern) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  render_views

  it "GET#index lists entries" do
    get :index
    expect(response).to be_ok
    expect(dom).to have_css "th", text: "Bezeichnung"
    expect(dom).to have_css "th", text: "Sortierschlüssel"
    expect(dom).to have_css "th", text: "Kurzbeschreibung"
    expect(dom).to have_css "th", text: "Beschreibung"
    expect(dom).to have_css "th", text: "Anforderungen"
    expect(dom).to have_css "th", text: "Geändert"
    expect(dom).to have_css "th", text: "Gelöscht"
    expect(dom).to have_css "td", text: "Kletterskala"
    expect(dom).to have_css "td", text: "LWSZSSSSASEX"
  end

  it "GET#edit shows form" do
    get :edit, params: {id: entry.id}

    expect(response).to be_ok
    expect(dom).to have_css "#content input", count: 7
  end

  it "GET#show redirects to edit" do
    get :show, params: {id: entry.id}
    expect(response).to redirect_to(edit_event_technical_requirement_path(entry))
  end

  it "POST#create creates new entry" do
    expect do
      post :create, params: {
        event_technical_requirement: {
          label: "Schneeschuhwandern",
          description: "Schnee",
          order: 10
        }
      }
    end.to change { Event::TechnicalRequirement.count }.by(1)

    entry = Event::TechnicalRequirement.last
    expect(entry.label).to eq("Schneeschuhwandern")
    expect(entry.description).to eq("Schnee")
    expect(entry.order).to eq(10)
    expect(entry.parent).to be_nil
  end

  it "PATCH#update updates entry" do
    patch :update, params: {
      id: entry.id,
      event_technical_requirement: {label: "Klettern"}
    }
    expect(response).to redirect_to(event_technical_requirements_path(returning: true))

    entry.reload
    expect(entry.label).to eq("Klettern")
  end

  it "DELETE#destroy cannot delete entry with children" do
    expect do
      delete :destroy, params: {id: entry.id}
      expect(response).to redirect_to(event_technical_requirements_path(returning: true))
    end.not_to change { Event::TechnicalRequirement.count }
    expect(flash[:alert]).to eq "Ein Eintrag mit Untereinträgen kann nicht gelöscht werden."
  end

  context "unauthorized" do
    let(:current_user) { people(:mitglied) }

    it "may not index" do
      expect do
        get :index
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
