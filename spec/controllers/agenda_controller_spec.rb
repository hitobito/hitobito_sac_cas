# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe AgendaController do
  render_views

  let(:group) { groups(:bluemlisalp) }
  let(:tour) { events(:section_tour) }
  let(:course) { events(:top_course) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before do
    tour.update!(globally_visible: true)
    tour.update_column(:state, :published)
    tour.dates.update_all(start_at: 1.month.from_now)

    course.update!(globally_visible: true)
    course.dates.update_all(start_at: 1.month.from_now)
    allow(course).to receive(:assert_type_is_allowed_for_groups).and_return(true)
    course.update(groups: [group])
  end

  describe "GET #index" do
    it "renders info alert when no group_id given" do
      get :index

      expect(response).to render_template(layout: "agenda")
      expect(dom).to have_content("Bitte geben Sie eine Sektion an, deren Anlässe angezeigt werden sollen")
    end

    it "renders without a layout" do
      get :index, params: {group_id: group.id}
      expect(response).to render_template(layout: "agenda")
    end

    it "includes globally visible tours for the specific group" do
      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).to include(tour)
    end

    it "excludes events that are not of type Event::Tour by default" do
      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).not_to include(course)
    end

    it "includes events that match the type filter" do
      get :index, params: {group_id: group.id, filters: {type: {types: ["Event::Course"]}}}
      expect(controller.send(:events)).to include(course)
    end

    it "excludes events from other groups" do
      tour.update!(groups: [groups(:matterhorn)])
      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours older than 12 months per default" do
      tour.dates.update_all(start_at: 13.months.ago)

      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "includes tours older than 12 months with since filter" do
      tour.dates.update_all(start_at: 13.months.ago)

      get :index, params: {group_id: group.id, filters: {date_range: {since: ["01.01.2020"]}}}
      expect(controller.send(:events)).to include(tour)
    end

    it "includes future tours per default" do
      tour.dates.update_all(start_at: 13.months.from_now)

      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).to include(tour)
    end

    it "excludes tours that are not globally_visible" do
      tour.update!(globally_visible: false)

      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours that are in state draft" do
      tour.update_column(:state, :draft)

      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).not_to include(tour)
    end
  end
end
