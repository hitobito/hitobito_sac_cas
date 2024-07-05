# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::KindsController do
  before { sign_in(current_user) }

  let(:current_user) { people(:admin) }
  let(:kind) { event_kinds(:ski_course) }

  it "permits additional attributes" do
    expect(described_class.permitted_attrs).to include(
      :cost_center_id,
      :cost_unit_id,
      :maximum_participants,
      :minimum_participants,
      :training_days,
      :season,
      :reserve_accommodation,
      :accommodation
    )
  end

  context "with rendered views" do
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    render_views

    it "GET#edit has push down button" do
      get :edit, params: {id: kind.id}
      expect(response).to be_ok

      link = dom.find_link "Daten auf Kurse übertragen"
      expect(link[:href]).to eq "/de/event_kinds/#{kind.id}/push_down"
      expect(link[:"data-method"]).to eq "put"
    end
  end

  it "POST#create creates new event_kind" do
    expect do
      post :create, params: {
        event_kind: {
          short_name: "Skitour",
          label: "Skitour",
          kind_category_id: event_kind_categories(:ski_course).id,
          level_id: event_levels(:ek).id,
          cost_center_id: cost_centers(:tour).id,
          cost_unit_id: cost_units(:ski).id
        }
      }
    end.to change { Event::Kind.count }.by(1)
  end

  it "PUT#push_down updates cost models on associated event_kinds" do
    course = events(:top_course)
    kind.update(maximum_participants: 10, minimum_participants: 0)
    course.update_columns(state: :created, kind_id: kind.id, minimum_age: 12)

    expect do
      put :push_down, params: {id: kind.id}
    end.to change { course.reload.maximum_participants }.from(nil).to(10)
      .and change { course.minimum_age }
  end

  context "unauthorized" do
    let(:current_user) { people(:mitglied) }

    it "may not push down" do
      expect do
        put :push_down, params: {id: kind.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
