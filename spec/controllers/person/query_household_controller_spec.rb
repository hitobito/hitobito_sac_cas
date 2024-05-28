# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Person::QueryHouseholdController do
  let(:person) { people(:admin) }
  let(:json) { JSON.parse(response.body) }
  before { sign_in(person) }

  context 'GET index' do
    context 'without reading permissions' do
      let(:person) { people(:mitglied) }

      it 'is unauthorized' do
        expect do
          get :index, params: { q: '1993' }
        end.to raise_error(CanCan::AccessDenied)
      end
    end


    it 'finds by birthday' do
      get :index, params: { q: '1993' }

      expect(json).to have(2).items
      expect(response.body).to match(/Magazina Leserat/)
      expect(response.body).to match(/Ida Paschke/)
    end

    it 'finds by id' do
      get :index, params: { q: '600004' }

      expect(json).to have(1).item
      expect(response.body).to match(/Nima Norgay/)
    end

    it 'finds by email' do
      get :index, params: { q: 'e.hillary@hitobito.example.com' }

      expect(json).to have(1).item
      expect(response.body).to match(/Edmund Hillary/)
    end

    it 'finds by first name' do
      get :index, params: { q: 'Tenzing' }

      expect(json).to have(1).item
      expect(response.body).to match(/Tenzing Norgay/)
    end

    it 'finds by last name' do
      get :index, params: { q: 'Norgay' }

      expect(json).to have(3).items
      expect(response.body).to match(/Tenzing Norgay/)
      expect(response.body).to match(/Frieda Norgay/)
      expect(response.body).to match(/Nima Norgay/)
    end
  end
end
