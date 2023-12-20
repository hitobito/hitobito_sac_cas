# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


require 'spec_helper'

describe :self_registration_neuanmeldung, js: true do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }
  let(:self_registration_role) { group.decorate.allowed_roles_for_self_registration.first }

  before do
    group.self_registration_role_type = self_registration_role
    group.save!

    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  def assert_aside(*birthdays)
    expect(page).to have_css('aside h2', text: "Beiträge in der Sektion #{group.name}")
    birthdays.each do |birthday|
      expect(page).to have_css('aside li', text: birthday)
    end
  end

  def complete_main_person_form
    assert_aside
    fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'
    click_on 'Weiter'
    choose 'Mann'
    fill_in 'Vorname', with: 'Max'
    fill_in 'Nachname', with: 'Muster'
    fill_in 'Adresse', with: 'Musterplatz'
    fill_in 'Geburtstag', with: '01.01.1980'
    fill_in 'Telefonnummer', with: '+41 79 123 45 56'
    fill_in 'self_registration_main_person_attributes_zip_code', with: '8000'
    fill_in 'self_registration_main_person_attributes_town', with: 'Zürich'
    find(:label, "Land").click
    find(:option, text: "Vereinigte Staaten").click
    expect(page).not_to have_field('Newsletter')
    expect(page).not_to have_field('Promocode')
    assert_aside('01.01.1980')
    yield if block_given?
    click_on 'Weiter'
  end

  describe 'existing email' do
    let(:person) { people(:admin) }
    let(:password) { 'really_b4dPassw0rD' }

    it 'redirects to login page' do
      person.update!(password: password, password_confirmation: password)

      visit group_self_registration_path(group_id: group)
      fill_in 'Mail', with: person.email
      click_on 'Weiter'
      expect(page).to have_css '.alert-success', text: 'Es existiert bereits ein Login für diese E-Mail.'
      expect(page).to have_css 'h1', text: 'Anmelden'
      expect(page).to have_field 'Haupt‑E‑Mail / Mitglied‑Nr', with: person.email
      fill_in 'Passwort', with: password
      click_on 'Anmelden'
      expect(page).to have_css 'h1', text: 'Registrierung zu SAC Blüemlisalp'
      expect(page).to have_button 'Beitreten'
    end
  end

  describe 'main_person' do
    let(:person) { Person.find_by(email: 'max.muster@hitobito.example.com') }
    it 'self registers and creates new person' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on 'Weiter als Einzelmitglied'

      expect do
        click_on 'Registrieren'
      end.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(page).to have_text('Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.')

      expect(person).to be_present
      expect(person.first_name).to eq 'Max'
      expect(person.last_name).to eq 'Muster'
      expect(person.address).to eq 'Musterplatz'
      expect(person.zip_code).to eq '8000'
      expect(person.town).to eq 'Zürich'
      expect(person.country).to eq 'US'
      expect(person.birthday).to eq Date.new(1980, 1, 1)

      person.confirm # confirm email

      person.password = person.password_confirmation = 'really_b4dPassw0rD'
      person.save!

      fill_in 'Haupt‑E‑Mail / Mitglied‑Nr', with: 'max.muster@hitobito.example.com'
      fill_in 'Passwort', with: 'really_b4dPassw0rD'

      click_button 'Anmelden'

      expect(person.roles.map(&:type)).to eq([self_registration_role.to_s])
      expect(current_path).to eq("/de#{group_person_path(group_id: group, id: person)}.html")
    end

    it 'persists newsletter and promocode as tags' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on 'Weiter als Einzelmitglied'

      check 'Ich möchte einen Newsletter abonnieren'
      fill_in 'Promocode', with: 'Promo'
      click_on 'Registrieren'
      expect(person.tags).to have(2).items
    end

    it 'can autocomplete address' do
      Address.create!(
        street_short: 'Belpstrasse',
        street_short_old: 'Belpstrasse',
        street_long: 'Belpstrasse',
        street_long_old: 'Belpstrasse',
        town: 'Bern',
        state: 'BE',
        zip_code: 3007,
        numbers: ['36', '37', '38', '40', '41', '5a', '5b', '6A', '6B']
      )
      visit group_self_registration_path(group_id: group)
      fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'
      click_on 'Weiter'
      fill_in 'Adresse', with: 'Belp'
      dropdown = find('ul[role="listbox"]')
      expect(dropdown).to have_content('Belpstrasse 3007 Bern')

      find('ul[role="listbox"] li[role="option"]', text: 'Belpstrasse 3007 Bern').click
      expect(page).to have_field('self_registration_main_person_attributes_zip_code', with: '3007')
      expect(page).to have_field('self_registration_main_person_attributes_town', with: 'Bern')
      expect(page).to have_field('self_registration_main_person_attributes_address', with: 'Belpstrasse')
    end

    describe 'with privacy policy' do
      before do
        file = Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png')
        image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, 'rb'),
                                                       filename: 'logo.png',
                                                       content_type: 'image/png').signed_id
        group.layer_group.update!(created_at: 1.minute.ago, privacy_policy: image)
        visit group_self_registration_path(group_id: group)
        complete_main_person_form
      end

      it 'sets privacy policy accepted' do
        click_on 'Weiter als Einzelmitglied'
        check 'Ich erkläre mich mit den folgenden Bestimmungen einverstanden:'

        expect do
          click_on 'Registrieren'
        end.to change { Person.count }.by(1)
        person = Person.find_by(email: 'max.muster@hitobito.example.com')
        expect(person.privacy_policy_accepted).to eq true
      end

      it 'rerenders third page when invalid and submitting from second' do
        click_on 'Weiter als Einzelmitglied'
        expect(page).to have_field 'Promocode'
        click_on 'Familienmitglieder'
        click_on 'Weiter als Einzelmitglied'
        expect(page).to have_content 'Um die Registrierung abzuschliessen, muss der ' \
          'Datenschutzerklärung zugestimmt werden.'
        expect(page).to have_css 'li.active a', text: 'Zusammenfassung'
      end
    end
  end

  describe 'household' do
    before do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      expect(page).to have_content 'Indem du weitere Personen hinzufügst, wählst du eine'
    end

    it 'validates household required fields' do
      click_on 'Eintrag hinzufügen'
      click_on 'Weiter als Familienmitgliedschaft'
      within '#housemates_fields .fields:nth-child(1)' do
        expect(page).to have_content 'Vorname muss ausgefüllt werden'
      end
    end

    it 'can create several people in same household' do
      click_on 'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(1)' do
        fill_in 'Vorname', with: 'Maxine'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1981'
        fill_in 'Haupt-E-Mail', with: 'maxine.muster@hitobito.example.com'
        choose 'weiblich'
      end
      assert_aside('01.01.1980', '01.01.1981')
      click_on  'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(2)' do
        fill_in 'Vorname', with: 'Maxi'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.2012'
        fill_in 'Haupt-E-Mail', with: 'maxi.muster@hitobito.example.com'
        choose 'andere'
      end
      assert_aside('01.01.1980', '01.01.1981', '01.01.2012')
      find('.btn-toolbar.bottom .btn-group button[type="submit"]', text: 'Weiter als Familienmitgliedschaft').click

      expect do
        click_on 'Registrieren'
      end.to change { Person.count }.by(3)
        .and change { Role.count }.by(3)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(page).to have_text('Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine ' \
                                'E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.')

      people = Person.where(last_name: 'Muster')
      expect(people).to have(3).items
      expect(people.pluck(:household_key).compact.uniq).to have(1).item
    end

    it 'can add and remove housemate' do
      click_on  'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(1)' do
        fill_in 'Vorname', with: 'Maxine'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1981'
        fill_in 'Haupt-E-Mail', with: 'maxine.muster@hitobito.example.com'
        choose 'weiblich'
      end
      assert_aside('01.01.1980', '01.01.1981')

      click_on  'Eintrag hinzufügen'
      within '#housemates_fields .fields:nth-child(2)' do
        fill_in 'Vorname', with: 'Maxi'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.2012'
        fill_in 'Haupt-E-Mail', with: 'maxi.muster@hitobito.example.com'
        choose 'andere'
      end
      assert_aside('01.01.1980', '01.01.1981', '01.01.2012')

      within '#housemates_fields .fields:nth-child(1)' do
        click_on 'Entfernen'
      end
      assert_aside('01.01.1980', '01.01.2012')
      click_on 'Weiter als Familienmitgliedschaft'

      expect do
        click_on 'Registrieren'
      end.to change { Person.count }.by(2)
      people = Person.where(last_name: 'Muster')
      expect(people).to have(2).items
      expect(people.pluck(:first_name)).to match_array(%w[Max Maxi])
    end

    it 'validates emails within household' do
      click_on  'Eintrag hinzufügen'

      fill_in 'Vorname', with: 'Maxine'
      fill_in 'Nachname', with: 'Muster'
      fill_in 'Geburtstag', with: '01.01.1981'
      fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'
      choose 'weiblich'
      click_on 'Weiter als Familienmitgliedschaft'
      expect(page).to have_content 'Haupt-E-Mail ist bereits vergeben'
      expect(page).to have_button 'Weiter als Familienmitgliedschaft'
    end

    it 'can continue with incomplete removed housemate' do
      click_on  'Eintrag hinzufügen'
      fill_in 'Vorname', with: 'Maxine'
      fill_in 'Nachname', with: 'Muster'
      within '#housemates_fields .fields:nth-child(1)' do
        click_on 'Entfernen'
      end
      click_on 'Weiter als Einzelmitglied'
      expect(page).to have_button 'Registrieren'
    end

    describe 'using step navigator' do
      it 'rerenders first page when invalid and submitting from second' do
        click_on 'Weiter als Einzelmitglied'
        expect(page).to have_field 'Promocode'
        click_on 'Personendaten'
        fill_in 'Vorname', with: ''
        click_on 'Weiter'
        expect(page).to have_content 'Vorname muss ausgefüllt werden'
      end
    end

    context 'bluemlisalp_neuanmeldungen_sektion' do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

      it 'validates birthday is valid' do
        click_on  'Eintrag hinzufügen'

        fill_in 'Vorname', with: 'Maxi'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: I18n.l(1.day.ago.to_date)
        fill_in 'Haupt-E-Mail', with: 'maxi.muster@hitobito.example.com'
        choose 'weiblich'
        click_on 'Weiter als Familienmitgliedschaft'
        expect(page).to have_content 'Person muss ein Geburtsdatum haben und mindestens 6 Jahre alt sein'
        expect(page).to have_content 'Beitragskategorie muss ausgefüllt werden'
      end
    end
  end
end
