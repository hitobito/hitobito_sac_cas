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
      params[:filter] = { id: person.id }
      render
    end

    context 'family_id' do
      it 'is included' do
        expect(jsonapi_data[0].attributes.symbolize_keys.keys).to include :family_id
      end
    end
  end
end
