# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Group::Sektion do
  context 'validations' do
    context 'section_canton' do
      def sektion(canton)
        Group::Sektion.new(section_canton: canton).tap(&:validate)
      end

      it 'allows valid canton' do
        expect(sektion('BE').errors[:section_canton]).to be_empty
      end

      it 'allows blank canton' do
        expect(sektion(nil).errors[:section_canton]).to be_empty
      end

      it 'does not allow invalid canton' do
        expect(sektion('Bern').errors[:section_canton]).to eq ['ist kein gültiger Wert']
        expect(sektion('').errors[:section_canton]).to eq ['ist kein gültiger Wert']
      end
    end
  end

end
