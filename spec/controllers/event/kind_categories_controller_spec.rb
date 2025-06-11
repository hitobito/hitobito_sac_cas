# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::KindCategoriesController do
  before { sign_in(current_user) }

  let(:current_user) { people(:admin) }
  let(:category) { event_kind_categories(:ski_course) }

  context "with rendered views" do
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    render_views

    it "GET#index lists cost_center and cost_unit" do
      get :index
      expect(response).to be_ok
      expect(dom).to have_css "th", text: "Kostenträger"
      expect(dom).to have_css "th", text: "Kostenstelle"
      expect(dom).to have_css "td", text: "ski-1 - Ski Technik"
      expect(dom).to have_css "td", text: "kurs-1 - Kurse"
    end

    it "GET#edit renders push down button" do
      get :edit, params: {id: category.id}
      expect(response).to be_ok

      link = dom.find_link "Werte auf Kursarten übertragen"
      expect(link[:href]).to eq "/de/event_kind_categories/#{category.id}/push_down"
      expect(link[:"data-method"]).to eq "put"
    end
  end

  it "POST#create creates new event_kind_category" do
    expect do
      post :create, params: {
        event_kind_category: {
          label: "Skitour",
          cost_center_id: cost_centers(:tour).id,
          cost_unit_id: cost_units(:ski).id
        }
      }
    end.to change { Event::KindCategory.count }.by(1)
  end

  it "PUT#push_down updates cost models on associated event_kinds" do
    event_kind = event_kinds(:ski_course)
    event_kind.update_columns(kind_category_id: category.id, cost_center_id: -1, cost_unit_id: -1)

    expect do
      put :push_down, params: {id: category.id}
    end.to change { event_kind.reload.cost_center_id }.from(-1).to(category.cost_center_id)
      .and change { event_kind.cost_unit_id }.from(-1).to(category.cost_unit_id)
  end

  context "unauthorized" do
    let(:current_user) { people(:mitglied) }

    it "may not push down" do
      expect do
        put :push_down, params: {id: category.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
