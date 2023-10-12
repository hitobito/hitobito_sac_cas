# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Role do

  let(:person) { Fabricate(:person) }
  let(:be_mitglieder) { groups(:be_mitglieder) }

  context 'Beitragskategorie' do
    it 'assigns correct beitragskategorie when creating new member role' do
      person.update!(birthday: Time.zone.today - 33.years)

      role = Group::SektionsMitglieder::Mitglied.create!(person: person, group: be_mitglieder)

      expect(role.beitragskategorie).to eq('einzel')
    end
  end

end
