# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::TraitsController do
  before { sign_in(current_user) }

  let(:current_user) { people(:admin) }
  let(:entry) { event_traits(:public_transport) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  render_views

  it "GET#index lists entries" do
    get :index
    expect(response).to be_ok
    expect(dom).to have_css "th", text: "Bezeichnung"
    expect(dom).to have_css "th", text: "Sortierschlüssel"
    expect(dom).to have_css "th", text: "Kurzbeschreibung"
    expect(dom).to have_css "th", text: "Beschreibung"
    expect(dom).to have_css "th", text: "Merkmale"
    expect(dom).to have_css "th", text: "Geändert"
    expect(dom).to have_css "th", text: "Gelöscht"
    expect(dom).to have_css "td", text: "Anreise"
    expect(dom).to have_css "td", text: "Anreise mit ÖV"
  end

  it "GET#edit shows form" do
    get :edit, params: {id: entry.id}

    expect(response).to be_ok
    expect(dom).to have_css "#content input", count: 7
  end

  it "GET#show redirects to edit" do
    get :show, params: {id: entry.id}
    expect(response).to redirect_to(edit_event_trait_path(entry))
  end

  it "POST#create creates new entry" do
    expect do
      post :create, params: {
        event_trait: {
          label: "Ausbildung",
          description: "Hier lernst du was",
          order: 9,
          parent_id: event_traits(:theme).id
        }
      }
    end.to change { Event::Trait.count }.by(1)

    entry = Event::Trait.last
    expect(entry.label).to eq("Ausbildung")
    expect(entry.description).to eq("Hier lernst du was")
    expect(entry.order).to eq(9)
    expect(entry.parent).to eq(event_traits(:theme))
  end

  it "PATCH#update updates entry" do
    patch :update, params: {
      id: entry.id,
      event_trait: {label: "Öffentlicher Verkehr", parent_id: nil}
    }
    expect(response).to redirect_to(event_traits_path(returning: true))

    entry.reload
    expect(entry.label).to eq("Öffentlicher Verkehr")
    expect(entry.parent_id).not_to be_nil
  end

  it "DELETE#destroy soft deletes referenced entry" do
    expect do
      delete :destroy, params: {id: entry.id}
      expect(response).to redirect_to(event_traits_path(returning: true))
    end.to change { Event::Trait.with_deleted.count }.by(0)
      .and change { Event::Trait.without_deleted.count }.by(-1)
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
