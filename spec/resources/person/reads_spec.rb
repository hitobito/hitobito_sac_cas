#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

RSpec.describe PersonResource, type: :resource do
  let(:ability) { Ability.new(people(:admin)) }

  describe 'serialization' do
    let(:person) { people(:mitglied) }

    before do
      params[:filter] = { id: { eq: person.id } }
    end

    context 'family_id' do
      it 'is included' do
        render
        expect(jsonapi_data[0].attributes.symbolize_keys.keys).to include :family_id
      end
    end

    context 'membership_years' do
      it 'is not included' do
        render
        expect(jsonapi_data[0].attributes.symbolize_keys.keys).not_to include :membership_years
      end

      it 'can be requested' do
        params[:extra_fields] = { people: 'membership_years' }
        render
        expect(jsonapi_data[0].attributes.symbolize_keys.keys).to include :membership_years
      end
    end
  end
end
