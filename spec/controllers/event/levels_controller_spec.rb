# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::LevelsController do
  before { sign_in(current_user) }
  let(:current_user) { people(:admin) }
  let(:level) { event_levels(:ek) }

  context 'with rendered views' do
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    render_views

    it 'GET#index lists cost_center and cost_unit' do
      get :index
      expect(response).to be_ok
      expect(dom).to have_css 'th', text: 'Bezeichnung'
      expect(dom).to have_css 'th', text: 'Code'
      expect(dom).to have_css 'th', text: 'Schwierigkeitsgrad'
      expect(dom).to have_css 'td', text: 'Einstiegskurs'
      expect(dom).to have_css 'td', text: '1'
    end

  end

  it 'POST#create creates new event_level' do
    expect do
      post :create, params: {
        event_level: {
          label: 'Experte',
          code: 3,
          difficulty: 5,
          description: 'Sehr schwer'
        }
      }
    end.to change { Event::Level.count }.by(1)

    level = Event::Level.last
    expect(level.label).to eq('Experte')
    expect(level.description).to eq('Sehr schwer')
    expect(level.code).to eq(3)
  end

  context 'unauthorized' do
    let(:current_user) { people(:mitglied) }

    it 'may not index' do
      expect do
        get :index
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
