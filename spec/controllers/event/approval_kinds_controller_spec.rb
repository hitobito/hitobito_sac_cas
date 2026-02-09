# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::ApprovalKindsController do
  before { sign_in(current_user) }

  let(:current_user) { people(:admin) }
  let(:entry) { event_approval_kinds(:professional) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  render_views

  it "GET#index lists entries" do
    get :index
    expect(response).to be_ok
    expect(dom).to have_css "th", text: "Name"
    expect(dom).to have_css "th", text: "Kurzbeschrieb"
    expect(dom).to have_css "th", text: "Reihenfolge"
    expect(dom).to have_css "th", count: 5
    expect(dom).to have_css "tbody tr", count: 3
  end

  it "GET#index can sort by order" do
    get :index, params: {sort: :order, sort_dir: :desc}

    expect(assigns(:approval_kinds).map(&:id)).to eq Event::ApprovalKind.order(order: :desc).pluck(:id)
  end

  it "GET#index can sort by name" do
    get :index, params: {sort: :name, sort_dir: :desc}

    expect(assigns(:approval_kinds).map(&:id)).to eq [
      event_approval_kinds(:security).id,
      event_approval_kinds(:editorial).id,
      event_approval_kinds(:professional).id
    ]
  end

  it "GET#edit shows form" do
    get :edit, params: {id: entry.id}

    expect(response).to be_ok
    expect(dom).to have_css "#content input", count: 7
  end

  it "POST#create creates new entry" do
    expect do
      post :create, params: {
        event_approval_kind: {
          name: "Sehr kompliziert Freigabestufe",
          short_description: "Nicht ganz so lange Beschreibung",
          order: 6
        }
      }
    end.to change { Event::ApprovalKind.count }.by(1)

    entry = Event::ApprovalKind.last
    expect(entry.name).to eq("Sehr kompliziert Freigabestufe")
    expect(entry.short_description).to eq("Nicht ganz so lange Beschreibung")
    expect(entry.order).to eq(6)
  end

  it "PATCH#update updates entry" do
    patch :update, params: {
      id: entry.id,
      event_approval_kind: {name: "Doch nicht mehr so komplizierte Freigabestufe"}
    }
    expect(response).to redirect_to(event_approval_kinds_path(returning: true))

    entry.reload
    expect(entry.name).to eq("Doch nicht mehr so komplizierte Freigabestufe")
  end

  it "DELETE#destroy hard deletes unreferenced entry" do
    expect do
      delete :destroy, params: {id: entry.id}
      expect(response).to redirect_to(event_approval_kinds_path(returning: true))
    end.to change { Event::ApprovalKind.with_deleted.count }.by(-1)
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
