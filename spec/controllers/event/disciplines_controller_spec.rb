# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::DisciplinesController do
  before { sign_in(current_user) }

  let(:current_user) { people(:admin) }
  let(:entry) { event_disciplines(:wanderweg) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  render_views

  describe "GET#index" do
    let(:wandern) { event_disciplines(:wandern) }
    let(:hochtour) { event_disciplines(:hochtour) }

    it "lists entries" do
      get :index
      expect(response).to be_ok
      expect(dom).to have_css "th", text: "Bezeichnung"
      expect(dom).to have_css "th", text: "Sortierschlüssel"
      expect(dom).to have_css "th", text: "Kurzbeschreibung"
      expect(dom).to have_css "th", text: "Beschreibung"
      expect(dom).to have_css "th", text: "Unterdisziplinen"
      expect(dom).to have_css "th", text: "Geändert"
      expect(dom).to have_css "th", text: "Gelöscht"
      expect(dom).to have_css "td", text: "Wandern"
      expect(dom).to have_css "td", text: "WanderwegBergtourSchneeschuhwandern"
    end

    it "renders colored circle if color is set" do
      wandern.update!(color: "#AABBCC")
      get :index
      expect(response).to be_ok
      expect(dom).to have_css("#event_discipline_#{wandern.id} td i.fa-circle")
      expect(dom).not_to have_css("#event_discipline_#{hochtour.id} td i.fa-circle")
      expect(dom.find("#event_discipline_#{wandern.id} td i.fa-circle")["style"]).to eq "color: #AABBCC"
    end
  end

  describe "GET#edit" do
    let(:wandern) { event_disciplines(:wandern) }

    it "shows form" do
      get :edit, params: {id: entry.id}

      expect(response).to be_ok
      expect(dom).to have_css "#content input", count: 7
    end

    it "shows color attribute for toplevel entry" do
      get :edit, params: {id: wandern.id}

      expect(response).to be_ok
      expect(dom).to have_css "#content input", count: 8
    end
  end

  it "GET#show redirects to edit" do
    get :show, params: {id: entry.id}
    expect(response).to redirect_to(edit_event_discipline_path(entry))
  end

  it "POST#create creates new entry" do
    expect do
      post :create, params: {
        event_discipline: {
          label: "Alpin",
          description: "Alpen",
          parent_id: event_disciplines(:klettern).id,
          order: 6,
          color: "#AABBCC"
        }
      }
    end.to change { Event::Discipline.count }.by(1)

    entry = Event::Discipline.last
    expect(entry.label).to eq("Alpin")
    expect(entry.description).to eq("Alpen")
    expect(entry.order).to eq(6)
    expect(entry.parent).to eq(event_disciplines(:klettern))
    expect(entry.color).to eq("#AABBCC")
  end

  it "PATCH#update updates deleted entry" do
    entry.destroy
    patch :update, params: {
      id: entry.id,
      event_discipline: {label: "Wanderwege"}
    }
    expect(response).to redirect_to(event_disciplines_path(returning: true))

    entry.reload
    expect(entry.label).to eq("Wanderwege")
    expect(entry.deleted_at).to be_nil
  end

  it "DELETE#destroy soft deletes referenced entry" do
    delete :destroy, params: {id: entry.id}
    expect(response).to redirect_to(event_disciplines_path(returning: true))

    entry.reload
    expect(entry.deleted_at).to be_present
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
