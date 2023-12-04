# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe :login, js: true do
  let(:password) { 'cNb@X7fTdiU4sWCMNos3gJmQV_d9e9' }
  let(:nickname) { 'foobar' }
  let(:person) { people(:mitglied).tap { |p| p.update!(password: password, nickname: 'foobar') } }

  around do |example|
    old_attrs = Person.devise_login_id_attrs.dup
    example.run
    Person.devise_login_id_attrs = old_attrs
  end

  it 'has correct login field label' do
    visit new_person_session_path
    expect(page).to have_selector('label[for="person_login_identity"]', text: 'Haupt‑E‑Mail / Mitglied‑Nr')
  end

  it 'allows login with email' do
    visit new_person_session_path
    fill_in 'person_login_identity', with: person.email
    fill_in 'person_password', with: password
    click_button 'Anmelden'

    expect(page).to have_link 'Abmelden'
    expect(page).to have_selector('.content-header h1', text: person.full_name)
  end

  it 'allows login with membership_number' do
    visit new_person_session_path
    fill_in 'person_login_identity', with: person.membership_number
    fill_in 'person_password', with: password
    click_button 'Anmelden'

    expect(page).to have_link 'Abmelden'
    expect(page).to have_selector('.content-header h1', text: person.full_name)
  end

  it 'does not allow login with nickname' do
    visit new_person_session_path
    fill_in 'person_login_identity', with: person.nickname
    fill_in 'person_password', with: password
    click_button 'Anmelden'

    expect(page).to have_selector('#flash .alert.alert-danger', text: 'Ungültige Anmeldedaten.')
    expect(page).to have_current_path(new_person_session_path(locale: :de))
  end
end
