# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::FitnessRequirementsController do
  before { sign_in(current_user) }

  let(:current_user) { people(:admin) }
  let(:entry) { event_fitness_requirements(:c) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  render_views

  it "GET#index lists entries" do
    get :index
    expect(response).to be_ok
    expect(dom).to have_css "th", text: "Bezeichnung"
    expect(dom).to have_css "th", text: "Sortierschlüssel"
    expect(dom).to have_css "th", text: "Kurzbeschreibung"
    expect(dom).to have_css "th", text: "Beschreibung"
    expect(dom).to have_css "th", text: "Geändert"
    expect(dom).to have_css "th", text: "Gelöscht"
    expect(dom).to have_css "th", count: 8
    expect(dom).to have_css "tbody tr", count: 5
  end

  it "GET#edit shows form" do
    get :edit, params: {id: entry.id}

    expect(response).to be_ok
    expect(dom).to have_css "#content input", count: 7
  end

  it "GET#show redirects to edit" do
    get :show, params: {id: entry.id}
    expect(response).to redirect_to(edit_event_fitness_requirement_path(entry))
  end

  it "POST#create creates new entry" do
    expect do
      post :create, params: {
        event_fitness_requirement: {
          label: "F - Hyper anstrengend",
          description: "24 Stunden und mehr",
          order: 6
        }
      }
    end.to change { Event::FitnessRequirement.count }.by(1)

    entry = Event::FitnessRequirement.last
    expect(entry.label).to eq("F - Hyper anstrengend")
    expect(entry.description).to eq("24 Stunden und mehr")
    expect(entry.order).to eq(6)
  end

  it "PATCH#update updates entry" do
    patch :update, params: {
      id: entry.id,
      event_fitness_requirement: {label: "C - Schono so"}
    }
    expect(response).to redirect_to(event_fitness_requirements_path(returning: true))

    entry.reload
    expect(entry.label).to eq("C - Schono so")
  end

  it "DELETE#destroy hard deletes unreferenced entry" do
    expect do
      delete :destroy, params: {id: entry.id}
      expect(response).to redirect_to(event_fitness_requirements_path(returning: true))
    end.to change { Event::FitnessRequirement.with_deleted.count }.by(-1)
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
