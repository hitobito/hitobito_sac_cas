
# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'self_registration_abo_magazin', js: true do
  let(:group) { groups(:abo_die_alpen) }

  before do
    group.update!(self_registration_role_type: group.role_types.first)
    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  def expect_active_step(title)
    expect(page).to have_css 'li.active', text: title
  end

  def expect_shared_partial
    expect(page).to have_text 'Preis pro Jahr'
  end

  def complete_main_person_form
    choose 'Mann'
    fill_in 'Vorname', with: 'Max'
    fill_in 'Nachname', with: 'Muster'
    fill_in 'Strasse und Nr', with: 'Musterplatz'
    fill_in 'Geburtstag', with: '01.01.1980'
    fill_in 'Telefon', with: '+41 79 123 45 56'
    fill_in 'self_registration_abo_magazin_main_person_attributes_zip_code', with: '8000'
    fill_in 'self_registration_abo_magazin_main_person_attributes_town', with: 'Zürich'
    check 'Ich habe die Statuten gelesen und stimme diesen zu'
    check 'Ich habe die Datenschutzerklärung gelesen und stimme diesen zu'
  end

  it 'creates person' do
    visit group_self_registration_path(group_id: group)
    expect_active_step 'Haupt-E-Mail'
    expect_shared_partial
    fill_in 'E-Mail', with: 'max.muster@hitobito.example.com'
    click_on 'Weiter'

    expect_active_step 'Personendaten'
    expect_shared_partial
    complete_main_person_form
    click_on 'Weiter'

    expect_active_step 'Abo'
    expect_shared_partial
    fill_in 'Ab Ausgabe', with: I18n.l(Date.tomorrow)

    expect do
      click_on 'Registrieren'
    end.to change { Person.count }.by(1)
  end

  it 'renders date validation message', js: true do
    visit group_self_registration_path(group_id: group)
    expect_active_step 'Haupt-E-Mail'
    expect_shared_partial
    fill_in 'E-Mail', with: 'max.muster@hitobito.example.com'
    click_on 'Weiter'

    expect_active_step 'Personendaten'
    expect_shared_partial
    complete_main_person_form
    click_on 'Weiter'

    expect_active_step 'Abo'
    expect_shared_partial
    fill_in 'Ab Ausgabe', with: I18n.l(Date.yesterday)

    expect do
      click_on 'Registrieren'
    end.not_to change { Person.count }
    expect(page).to have_text "Ab Ausgabe muss #{I18n.l(Date.today)} oder danach sein"
  end
end
