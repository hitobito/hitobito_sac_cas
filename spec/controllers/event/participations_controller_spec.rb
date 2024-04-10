# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::ParticipationsController do
  before { sign_in(people(:admin)) }

  let(:group) { event.groups.first }
  let(:event) do
    Fabricate(:sac_course, groups: [groups(:root)], applications_cancelable: true).tap do |c|
      c.dates.first.update_columns(start_at: 1.day.from_now)
    end
  end
  let(:params) { { group_id: group.id, event_id: event.id } }

  describe 'GET#index' do
    render_views
    subject(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      participation = Fabricate(:event_participation, event: event)
      Fabricate(Event::Role::Participant.sti_name, participation: participation)
    end

    it 'renders state column' do
      get :index, params: params
      expect(dom).to have_css 'th a', text: 'Status'
      expect(dom).to have_css 'td', text: 'Bestätigt'
    end

    context 'event without state' do
      let(:event) { events(:top_event) }

      it 'hides state column' do
        get :index, params: params
        expect(dom).not_to have_css 'th a', text: 'Status'
        expect(dom).not_to have_css 'td', text: 'Bestätigt'
      end
    end
  end

  context 'GET#new' do
    render_views
    let(:dom)  { Capybara::Node::Simple.new(response.body) }

    it 'does not render aside for event' do
      event = Fabricate(:event)
      get :new, params: { group_id: event.groups.first.id, event_id: event.id }
      expect(dom).to have_css '#content > form'
      expect(dom).to have_css '.stepwizard-step', count: 2
      expect(dom).to have_css '.stepwizard-step.is-current', text: 'Zusatzdaten'
      expect(dom).not_to have_css 'aside'
    end

    it 'does not render aside and wizard for someone else' do
      get :new, params: { group_id: group.id, event_id: course.id, for_someone_else: true }
      expect(dom).to have_css '#content > form'
      expect(dom).not_to have_css '.stepwizard-step', count: 2
      expect(dom).not_to have_css 'aside'
    end

    it 'renders aside for course' do
      get :new, params: { group_id: group.id, event_id: event.id }
      expect(dom).to have_css 'main form'
      expect(dom).to have_css '.stepwizard-step', count: 3
      expect(dom).to have_css '.stepwizard-step.is-current', text: 'Zusatzdaten'
      expect(dom).to have_css 'aside.card', count: 2
    end
  end

  context 'GET#show' do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }
    let(:participation) { Fabricate(:event_participation, event: event) }
    let(:params) { { group_id: group.id, event_id: event.id, id: participation.id } }

    it 'includes cancel_statement field in cancel popover' do
      Fabricate(:event_application, participation: participation, priority_1: event,
                  priority_2: event)
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
    render_views
    let(:dom)  { Capybara::Node::Simple.new(response.body) }
    let(:participation_id) { assigns(:participation).id }
    let(:new_subsidy_path) { new_group_event_participation_subsidy_path(participation_id: participation_id) }
    let(:participation_path) { group_event_participation_path(id: participation_id) }
    let(:mitglieder) { groups(:bluemlisalp_mitglieder) }

    context 'event' do
      let(:course) { Fabricate(:event) }

      it 'redirects to participation path' do
        post :create, params: params.except(:id)
        expect(response).to redirect_to(participation_path)
      end
    end

    it 'redirects to participation path' do
      post :create, params: params.except(:id).merge(step: 'summary')
      expect(response).to redirect_to(participation_path)
    end

    context 'not subsidizable' do
      it 'renders summary after answers' do
        post :create, params: params.except(:id).merge(step: 'answers')
        expect(response).to render_template('new')
        expect(dom).to have_css '.stepwizard-step', count: 3
        expect(dom).to have_css '.stepwizard-step.is-current', text: 'Zusammenfassung'
      end

      it 'goes back to answers from summary' do
        post :create, params: params.except(:id).merge(step: 'summary', back: 'true')
        expect(response).to render_template('new')
        expect(dom).to have_css '.stepwizard-step', count: 3
        expect(dom).to have_css '.stepwizard-step.is-current', text: 'Zusatzdaten'
      end

      it 'redirects to contact data when going back from answers' do
        post :create, params: params.except(:id).merge(step: 'answers', back: 'true')
        expect(response).to redirect_to(contact_data_group_event_participations_path(group, course))
      end
    end

    context 'subsidizable' do
      before { Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: mitglieder, person: people(:admin), beitragskategorie: :einzel) }

      it 'renders subsidy after answers' do
        post :create, params: params.except(:id).merge(step: 'answers')
        expect(response).to render_template('new')
        expect(dom).to have_css '.stepwizard-step', count: 4
        expect(dom).to have_css '.stepwizard-step.is-current', text: 'Subventionsbeitrag'
      end

      it 'goes back to subsidy from summary' do
        post :create, params: params.except(:id).merge(step: 'summary', back: true)
        expect(response).to render_template('new')
        expect(dom).to have_css '.stepwizard-step', count: 4
        expect(dom).to have_css '.stepwizard-step.is-current', text: 'Subventionsbeitrag'
      end
    end

  end

  context 'state changes' do
    let(:participation) { Fabricate(:event_participation, event: event) }
    let(:params) { { group_id: group.id, event_id: event.id, id: participation.id } }

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
      event.update_columns(applications_cancelable: false)
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

