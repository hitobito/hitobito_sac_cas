# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::ApplicationMarketController do
  include ActiveJob::TestHelper

  before { sign_in(people(:admin)) }

  let(:group) { event.groups.first }
  let(:event) { events(:top_course) }
  let(:params) { {group_id: group.id, event_id: event.id} }

  def create_participation(attrs = {})
    Fabricate(:event_participation, attrs.merge(event: event)).tap do |p|
      Fabricate(Event::Course::Role::Participant.sti_name, participation: p)
    end
  end

  def create_application(attrs = {})
    application = Fabricate(:event_application, priority_1: event, priority_2: event)
    create_participation(attrs.merge(application: application))
  end

  describe "GET#index" do
    it "sorts participants oldest first" do
      older = create_participation(created_at: 2.days.ago)
      newer = create_participation(created_at: 1.day.ago)
      oldest = create_participation(created_at: 5.days.ago)

      get :index, params: params
      expect(assigns(:participants).map(&:id)).to eq [oldest, older, newer].map(&:id)
    end

    it "sorts applications oldest first" do
      older = create_application(created_at: 2.days.ago)
      newer = create_application(created_at: 1.day.ago)
      oldest = create_application(created_at: 5.days.ago)

      get :index, params: params
      expect(assigns(:applications).map(&:id)).to eq [oldest, older, newer].map(&:id)
    end

    describe "view" do
      render_views
      subject(:dom) { Capybara::Node::Simple.new(response.body) }

      before do
        create_application.tap { |p| p.update_columns(active: true, state: :assigned) }
        create_application.tap { |p| p.update_columns(active: false, state: :applied) }
      end

      it "shows participation state for applications" do
        get :index, params: params
        expect(dom).to have_css "tbody#applications tr:nth-of-type(1) td", text: "Warteliste"
        expect(dom).to have_css "tbody#participants tr:nth-of-type(1) td", text: "Bestätigt"
      end

      it "hides participation station when event possible_participation_states is blank" do
        allow(Event::Course).to receive(:possible_participation_states).and_return([])
        get :index, params: params
        expect(dom).not_to have_css "tbody#applications tr:nth-of-type(1) td", text: "Warteliste"
        expect(dom).not_to have_css "tbody#participants tr:nth-of-type(1) td", text: "Bestätigt"
      end
    end

    describe "summoned" do
      render_views
      subject(:dom) { Capybara::Node::Simple.new(response.body) }

      before do
        create_application.tap { |p| p.update_columns(active: true, state: :summoned) }
      end

      it "shows summoned applications on the left side" do
        get :index, params: params
        expect(dom).to have_css "tbody#participants tr:nth-of-type(1) td", text: "Aufgeboten"
      end
    end
  end

  describe "PUT #add_participant" do
    let(:appl_prio_1) do
      p = Fabricate(:event_participation,
                    event: event,
                    active: false,
                    application: Fabricate(:event_application, priority_1: event))
      Fabricate(Event::Course::Role::Participant.name.to_sym, participation: p)
      p.reload
    end

    it "sends confirmation email" do
      expect do
        put :add_participant, params: {group_id: group.id, event_id: event.id, id: appl_prio_1.id}, format: :js
      end.to have_enqueued_mail(Event::ApplicationConfirmationMailer, :confirmation)

      expect(appl_prio_1.reload.roles.collect(&:type)).to eq([event.participant_types.first.sti_name])
      expect(appl_prio_1).to be_active
    end
  end
end
