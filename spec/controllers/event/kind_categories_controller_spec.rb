# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::KindCategoriesController do
  before { sign_in(people(:admin)) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  describe 'GET#index' do
    render_views

    it 'GET#index lists cost_center and cost_unit' do
      get :index
      expect(response).to be_ok
      expect(dom).to have_css 'th', text: 'Kostenträger'
      expect(dom).to have_css 'th', text: 'Kostenstelle'
      expect(dom).to have_css 'td', text: 'ski-1 - Ski Technik'
      expect(dom).to have_css 'td', text: 'kurs-1 - Kurse'
    end
  end

  it 'POST#create creates new event_kind_category' do
    expect do
      post :create, params: {
        event_kind_category: {
          label: 'Skitour',
          cost_center_id: cost_centers(:tour).id,
          cost_unit_id: cost_units(:ski).id
        }
      }
    end.to change { Event::KindCategory.count }.by(1)
  end
end
