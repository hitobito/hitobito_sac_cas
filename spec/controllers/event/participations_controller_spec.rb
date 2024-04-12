# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::ParticipationsController do
  before { sign_in(people(:admin)) }
  let(:group) { course.groups.first }
  let(:course) do
    Fabricate(:sac_course, groups: [groups(:root)], applications_cancelable: true).tap do |c|
      c.dates.first.update_columns(start_at: 1.day.from_now)
    end
  end
  let(:participation) { Fabricate(:event_participation, event: course) }
  let(:params) { { group_id: group.id, event_id: course.id, id: participation.id } }

  context 'GET#new' do
    render_views
    let(:dom)  { Capybara::Node::Simple.new(response.body) }

    it 'does not render aside for event' do
      event = Fabricate(:event)
      get :new, params: { group_id: event.groups.first.id, event_id: event.id }
      expect(dom).to have_css '#content > form'
      expect(dom).not_to have_css 'aside'
    end

    it 'renders aside for course' do
      get :new, params: { group_id: group.id, event_id: course.id }
      expect(dom).to have_css 'main form'
      expect(dom).to have_css 'aside.card', count: 2
    end
  end

  context 'GET#show' do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it 'includes cancel_statement field in cancel popover' do
      Fabricate(:event_application, participation: participation, priority_1: course,
                  priority_2: course)
      get :show, params: params
      button = dom.find_button 'Abmelden'
      content = Capybara::Node::Simple.new(button['data-bs-content'])
      expect(content).to have_field 'Begründung'
    end

    it 'includes cancel_statement on show page' do
      participation.update_columns(cancel_statement: 'maybe next time', state: :canceled)

      get :show, params: params
      expect(dom).to have_css 'dt', text: 'Begründung'
      expect(dom).to have_css 'dl', text: 'maybe next time'
    end
  end

  context 'POST#create' do
    let(:participation_id) { assigns(:participation).id }
    let(:new_subsidy_path) { new_group_event_participation_subsidy_path(participation_id: participation_id) }
    let(:participation_path) { group_event_participation_path(id: participation_id) }
    let(:mitglieder) { groups(:bluemlisalp_mitglieder) }

    context 'event' do
      let(:event) { Fabricate(:event) }

      it 'redirects to participation path' do
        post :create, params: params.except(:id)
        expect(response).to redirect_to(participation_path)
      end
    end

    it 'redirects to participation path when participation is not subsidizable' do
      post :create, params: params.except(:id)
      expect(response).to redirect_to(participation_path)
    end

    it 'redirects to subsidies if participation is for a mitglied' do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: mitglieder, person: people(:admin), beitragskategorie: :einzel)
      post :create, params: params.except(:id)
      expect(response).to redirect_to(new_subsidy_path)
    end
  end

  context 'state changes' do
    it 'PUT summon sets participation state to abset' do
      put :summon, params: params
      participation.reload
      expect(participation.active).to be false
      expect(participation.state).to eq 'summoned'
      expect(flash[:notice]).to match /wurde aufgeboten/
    end

    it 'PUT#cancel sets statement and default canceled_at' do
      freeze_time
      put :cancel, params: params.merge({
        event_participation: { cancel_statement: 'next time!' }
      })
      participation.reload
      expect(participation.state).to eq 'canceled'
      expect(participation.canceled_at).to eq Time.zone.today
      expect(participation.cancel_statement).to eq 'next time!'
    end

    it 'PUT#cancel can override canceled_at' do
      freeze_time
      put :cancel, params: params.merge({
        event_participation: { canceled_at: 1.day.ago }
      })
      participation.reload
      expect(participation.state).to eq 'canceled'
      expect(participation.canceled_at).to eq 1.day.ago.to_date
      expect(participation.cancel_statement).to be_nil
    end

    it 'PUT#cancel cannot override canceled_at when canceling own participation' do
      freeze_time
      participation.update!(person: people(:admin))
      put :cancel, params: params.merge({
        event_participation: { canceled_at: 1.day.ago }
      })
      participation.reload
      expect(participation.state).to eq 'canceled'
      expect(participation.canceled_at).to eq Time.zone.today
      expect(participation.cancel_statement).to be_nil
    end

    it 'PUT#cancel fails if participation cancels but not cancelable by participant' do
      freeze_time
      course.update_columns(applications_cancelable: false)
      participation.update!(person: people(:admin))
      put :cancel, params: params.merge({
        event_participation: { canceled_at: 1.day.ago }
      })
      participation.reload
      expect(participation.state).to eq 'assigned'
      expect(flash[:alert]).to eq ['ist nicht gültig']
    end
  end
end

