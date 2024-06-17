# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe HouseholdsController, type: :controller do

  render_views

  let(:group)  { groups(:bluemlisalp) }
  let(:person) { people(:admin) }
  let(:familienmitglied) { people(:familienmitglied) }
  let(:params) { { group_id: group.id, person_id: familienmitglied.id } }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(person) }

  describe 'GET #edit' do
    it 'checks that we are using sac terms' do
      get :edit, params: params
      expect(dom).to have_content('Familie verwalten')
      expect(dom).not_to have_content('Haushalt verwalten')
      expect(dom).not_to have_content('Haushaltsadresse')
      expect(dom).to have_content('Familienmitglieder')
    end
  end
end
