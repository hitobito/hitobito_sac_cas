# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe EventsController do
  before { sign_in(person) }

  let(:group) { groups(:root) }

  before { travel_to(Time.zone.local(2024, 4, 1)) }

  describe "GET#index" do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }
    let(:params) { {group_id: group.id, type: "Event::Course"} }
    let(:top_course) { events(:top_course) }

    context "with permission" do
      let(:person) { people(:admin) }

      before do
        top_course.update!(unconfirmed_count: 2)
        top_course.dates.first.update_columns(start_at: Time.zone.now)
      end

      it "renders unconfirmed column" do
        get :index, params: params
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
end
