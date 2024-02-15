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
  end
end
