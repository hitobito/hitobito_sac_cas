# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe :self_registration do
  let(:group) { groups(:abo_die_alpen) }

  before do
    group.update!(self_registration_role_type: group.role_types.first)
    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  it 'creates person' do
    visit group_self_registration_path(group_id: group)
    expect(page).to have_text 'Preis pro Jahr'

    fill_in 'Ab Ausgabe', with: '01.01.2010'
    click_on 'Weiter'
    expect(page).to have_text 'Preis pro Jahr'

    fill_in 'E-Mail', with: 'max.muster@hitobito.example.com'
    choose 'Mann'
    fill_in 'Vorname', with: 'Max'
    fill_in 'Nachname', with: 'Muster'
    fill_in 'Strasse und Nr.', with: 'Musterplatz'
    fill_in 'Geburtstag', with: '01.01.1980'
    fill_in 'Mobil', with: '+41 79 123 45 56'
    fill_in 'self_registration_abo_main_person_attributes_zip_code', with: '8000'
    fill_in 'self_registration_abo_main_person_attributes_town', with: 'Zürich'
    expect do
      click_on 'Registrieren'
    end.to change { Person.count }.by(1)

    person = Person.find_by(email: 'max.muster@hitobito.example.com')

    expect(person).to be_present

    phone_number = person.phone_numbers.first
    expect(phone_number).to be_present
    expect(phone_number.label).to eq('Mobil')
    expect(phone_number.number).to eq('+41 79 123 45 56')
  end
end
