# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe :self_registration_neuanmeldung, js: true do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:self_registration_role) { group.decorate.allowed_roles_for_self_registration.first }
  let(:person) { Person.find_by(email: 'max.muster@hitobito.example.com') }

  before do
    group.self_registration_role_type = self_registration_role
    group.save!

    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  def assert_aside(*birthdays)
    expect(page).to have_css('aside h2', text: 'Fragen zur Mitgliedschaft?')
    expect(page).to have_css('aside#fees h2', text: "Beiträge in der Sektion #{group.layer_group.name}")
    birthdays.each do |birthday|
      expect(page).to have_css('aside#fees li', text: birthday)
    end
  end

  def complete_main_person_form
    assert_aside
    fill_in 'E-Mail', with: 'max.muster@hitobito.example.com'
    click_on 'Weiter'
    choose 'Mann'
    fill_in 'Vorname', with: 'Max'
    fill_in 'Nachname', with: 'Muster'
    fill_in 'Strasse und Nr.', with: 'Musterplatz'
    fill_in 'Geburtstag', with: '01.01.1980'
    fill_in 'Telefon', with: '+41 79 123 45 56'
    fill_in 'self_registration_sektion_main_person_attributes_zip_code', with: '8000'
    fill_in 'self_registration_sektion_main_person_attributes_town', with: 'Zürich'
    find(:label, "Land").click
    find(:option, text: "Vereinigte Staaten").click
    expect(page).not_to have_field('Newsletter')
    assert_aside('01.01.1980')
    yield if block_given?
    click_on 'Weiter'
  end

  def complete_last_page(with_adult_consent: false)
    if with_adult_consent
      check 'Ich bestätige, dass ich mindestens 18 Jahre alt bin oder das Einverständnis meiner Erziehungsberechtigten habe'
    end
    check 'Ich habe die Statuten gelesen und stimme diesen zu'
    check 'Ich habe das Beitragsreglement gelesen und stimme diesen zu'
    check 'Ich habe die Datenschutzerklärung gelesen und stimme diesen zu'
    yield if block_given?
    click_on 'Registrieren'
  end

  describe 'existing email' do
    let(:person) { people(:admin) }
    let(:password) { 'really_b4dPassw0rD' }

    it 'redirects to login page' do
      person.update!(password: password, password_confirmation: password)

      visit group_self_registration_path(group_id: group)
      fill_in 'Mail', with: person.email
      click_on 'Weiter'
      expect(page).to have_css '.alert-success',
text: 'Es existiert bereits ein Login für diese E-Mail.'
      expect(page).to have_css 'h1', text: 'Anmelden'
      expect(page).to have_field 'Haupt‑E‑Mail / Mitglied‑Nr', with: person.email
      fill_in 'Passwort', with: password
      click_on 'Anmelden'
      expect(page).to have_css 'h1', text: 'Registrierung zu SAC Blüemlisalp'
      expect(page).to have_button 'Beitreten'
    end
  end

  describe 'main_person' do
    it 'self registers and creates new person' do
      visit group_self_registration_path(group_id: group)
      expect(page).to have_css('h2', text: 'Fragen zur Mitgliedschaft?')
      complete_main_person_form
      click_on 'Weiter als Einzelmitglied', match: :first

      expect do
        complete_last_page
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
      fill_in 'E-Mail', with: 'max.muster@hitobito.example.com'
      click_on 'Weiter'
      fill_in 'Strasse und Nr.', with: 'Belp'
      dropdown = find('ul[role="listbox"]')
      expect(dropdown).to have_content('Belpstrasse 3007 Bern')

      find('ul[role="listbox"] li[role="option"]', text: 'Belpstrasse 3007 Bern',
match: :first).click
      expect(page).to have_field('self_registration_sektion_main_person_attributes_zip_code', with: '3007')
      expect(page).to have_field('self_registration_sektion_main_person_attributes_town', with: 'Bern')
      expect(page).to have_field('self_registration_sektion_main_person_attributes_address',
with: 'Belpstrasse')
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
      click_on 'Weiter als Familienmitgliedschaft', match: :first
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
        fill_in 'E-Mail (optional)', with: 'maxine.muster@hitobito.example.com'
        choose 'weiblich'
      end
      assert_aside('01.01.1980', '01.01.1981')
      click_on  'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(2)' do
        fill_in 'Vorname', with: 'Maxi'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.2012'
        fill_in 'E-Mail (optional)', with: 'maxi.muster@hitobito.example.com'
        choose 'andere'
      end
      assert_aside('01.01.1980', '01.01.1981', '01.01.2012')
      find('.btn-toolbar.bottom .btn-group button[type="submit"]',
text: 'Weiter als Familienmitgliedschaft').click

      expect do
        complete_last_page
      end.to change { Person.count }.by(3)
        .and change { Role.count }.by(3)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(page).to have_text('Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine ' \
                                'E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.')

      people = Person.where(last_name: 'Muster')
      expect(people).to have(3).items
      expect(people.pluck(:household_key).compact.uniq).to have(1).item
    end

    it 'validates we only can have one additional adult in household' do
      click_on  'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(1)' do
        fill_in 'Vorname', with: 'Maxine'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1981'
        fill_in 'E-Mail (optional)', with: 'maxine.muster@hitobito.example.com'
        choose 'weiblich'
      end
      assert_aside('01.01.1980', '01.01.1981')

      click_on  'Eintrag hinzufügen'
      within '#housemates_fields .fields:nth-child(2)' do
        fill_in 'Vorname', with: 'Maxi'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1978'
        fill_in 'E-Mail (optional)', with: 'maxi.muster@hitobito.example.com'
        choose 'andere'
      end
      assert_aside('01.01.1980', '01.01.1981', '01.01.1978')

      click_on 'Weiter als Familienmitgliedschaft', match: :first
      expect(page).to have_content 'In einer Familienmitgliedschaft sind maximal 2 Erwachsene inbegriffen.'
    end

    it 'cannot add and remove housemate' do
      click_on  'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(1)' do
        fill_in 'Vorname', with: 'Maxine'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1981'
        fill_in 'E-Mail (optional)', with: 'maxine.muster@hitobito.example.com'
        choose 'weiblich'
      end
      assert_aside('01.01.1980', '01.01.1981')

      click_on  'Eintrag hinzufügen'
      within '#housemates_fields .fields:nth-child(2)' do
        fill_in 'Vorname', with: 'Maxi'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.2012'
        fill_in 'E-Mail (optional)', with: 'maxi.muster@hitobito.example.com'
        choose 'andere'
      end
      assert_aside('01.01.1980', '01.01.1981', '01.01.2012')

      within '#housemates_fields .fields:nth-child(1)' do
        click_on 'Entfernen'
      end
      assert_aside('01.01.1980', '01.01.2012')
      click_on 'Weiter als Familienmitgliedschaft', match: :first

      expect do
        complete_last_page
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
      fill_in 'E-Mail (optional)', with: 'max.muster@hitobito.example.com'
      choose 'weiblich'
      click_on 'Weiter als Familienmitgliedschaft', match: :first
      expect(page).to have_content 'E-Mail (optional) ist bereits vergeben'
      expect(page).to have_button 'Weiter als Familienmitgliedschaft', match: :first
    end

    it 'validates phone_number of housemate' do
      click_on  'Eintrag hinzufügen'

      fill_in 'Vorname', with: 'Maxine'
      fill_in 'Nachname', with: 'Muster'
      fill_in 'Geburtstag', with: '01.01.1981'
      fill_in 'E-Mail (optional)', with: 'max.muster@hitobito.example.com'
      fill_in 'Telefon (optional)', with: '123'
      choose 'weiblich'
      click_on 'Weiter als Familienmitgliedschaft', match: :first
      within '#housemates_fields .fields:nth-child(1)' do
        expect(page).to have_content 'Telefon (optional) ist nicht gültig'
      end
    end

    it 'can continue with incomplete removed housemate' do
      click_on  'Eintrag hinzufügen'
      fill_in 'Vorname', with: 'Maxine'
      fill_in 'Nachname', with: 'Muster'
      within '#housemates_fields .fields:nth-child(1)' do
        click_on 'Entfernen'
      end
      click_on 'Weiter als Einzelmitglied', match: :first
      expect(page).to have_button 'Registrieren'
    end

    describe 'using step navigator' do
      it 'rerenders first page when invalid and submitting from second' do
        click_on 'Weiter als Einzelmitglied', match: :first
        check 'Ich habe die Statuten gelesen und stimme diesen zu'
        check 'Ich habe das Beitragsreglement gelesen und stimme diesen zu'
        check 'Ich habe die Datenschutzerklärung gelesen und stimme diesen zu'
        click_on 'Personendaten'
        fill_in 'Vorname', with: ''
        click_on 'Weiter'
        expect(page).to have_content 'Vorname muss ausgefüllt werden'
      end

      it 'renders partial according to next step in wizard' do
        click_on 'Weiter als Einzelmitglied', match: :first
        check 'Ich habe die Statuten gelesen und stimme diesen zu'
        click_on 'Haupt-E-Mail'
        expect(page).to have_css 'li.active', text: 'Haupt-E-Mail'
        expect(page).to have_button 'Weiter'
        click_on 'Weiter'
        expect(page).to have_css 'li.active', text: 'Personendaten'
      end

      it 'shows buttons when navigating back and removing housemate' do
        click_on  'Eintrag hinzufügen'

        fill_in 'Vorname', with: 'Maxine'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1981'
        click_on 'Weiter als Familienmitgliedschaft', match: :first
        expect(page).to have_css 'li.active', text: 'Zusatzdaten'
        click_on 'Familienmitglieder'
        expect(page).to have_button 'Weiter als Familienmitglied'
        click_on 'Entfernen'
        expect(page).to have_button 'Weiter als Einzelmitglied'
      end
    end

    context 'bluemlisalp_neuanmeldungen_sektion' do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

      it 'validates birthday is valid' do
        click_on  'Eintrag hinzufügen'

        fill_in 'Vorname', with: 'Maxi'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: I18n.l(1.day.ago.to_date)
        fill_in 'E-Mail (optional)', with: 'maxi.muster@hitobito.example.com'
        choose 'weiblich'
        click_on 'Weiter als Familienmitgliedschaft', match: :first
        expect(page).to have_content 'Person muss ein Geburtsdatum haben und mindestens 6 Jahre alt sein'
      end
    end

    context 'button groups' do
      it 'has only bottom button toolbar without hosemate' do
        expect(page).to have_selector('.btn-toolbar.bottom')
        expect(page).to have_no_selector('.btn-toolbar.top')
      end

      it 'has both button groups with housemate' do
        click_on('Eintrag hinzufügen')

        expect(page).to have_selector('.btn-toolbar.bottom')
        expect(page).to have_selector('.btn-toolbar.top')
      end

      it 'has both button groups with housemate when navigating back' do
        click_on('Eintrag hinzufügen')
        fill_in 'Vorname', with: 'Max'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1980'
        within('.btn-toolbar.top') do
          click_on('Weiter als Familienmitgliedschaft')
        end
        expect(page).to have_css('li.active', text: 'Zusatzdaten')
        click_on('Zurück')

        expect(page).to have_selector('.btn-toolbar.bottom')
        expect(page).to have_selector('.btn-toolbar.top')
      end
    end
  end

  describe 'household age validations' do
    let(:twenty_years_ago) { I18n.l(20.years.ago.to_date) }
    it 'skips household when person is too young' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form do
        fill_in 'Geburtstag', with: twenty_years_ago
      end
      expect(page).to have_css 'li.active', text: 'Zusatzdaten'
      expect(page).not_to have_link 'Familienmitglieder'
    end

    it 'clears household members when person is too young' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on  'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(1)' do
        fill_in 'Vorname', with: 'Maxine'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1981'
        fill_in 'E-Mail (optional)', with: 'maxine.muster@hitobito.example.com'
        choose 'weiblich'
      end

      click_on 'Personendaten'
      fill_in 'Geburtstag', with: twenty_years_ago
      click_on 'Weiter'
      assert_aside(twenty_years_ago)
      expect do
        complete_last_page
      end.to change { Person.count }.by(1)
    end
  end

  describe 'supplements' do
    let(:root) { groups(:root) }
    let(:list) { Fabricate(:mailing_list, group: root) }

    before do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on 'Weiter als Einzelmitglied', match: :first
    end

    it 'creates excluding subscription if newsletter is unchecked' do
      root.update!(sac_newsletter_mailing_list_id: list.id)
      uncheck 'Ich möchte einen Newsletter abonnieren'
      complete_last_page
      expect(person.subscriptions.excluded).to have(1).items
    end

    it 'persists self_registration_reason' do
      SelfRegistrationReason.create!(text: 'naja')
      reason = SelfRegistrationReason.create!(text: 'soso')
      expect(page).to have_css('label', text: 'Eintrittsgrund')
      choose 'soso'
      complete_last_page
      expect(person.self_registration_reason).to eq reason
    end

    context 'future role'do
      around do |example|
        travel_to(Date.new(2023, 3, 1)) do
          example.run
        end
      end

      it 'creates future role for main person' do
        expect(page).to have_css('label', text: 'Eintrittsdatum per')
        choose '01. Juli'
        expect do
          complete_last_page
        end.to change { FutureRole.count }.by(1)
        expect(FutureRole.first.convert_on).to eq Date.new(2023, 7, 1)
      end
    end
  end

  describe 'with adult consent' do
    before do
      group.update!(self_registration_require_adult_consent: true)
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on 'Weiter als Einzelmitglied', match: :first
    end

    it 'cannot complete without accepting adult consent' do
      expect { complete_last_page }.not_to change { Person.count }
      expect(page).to have_text 'Einverständniserklärung der Erziehungsberechtigten muss akzeptiert werden'
    end

    it 'can complete when accepting adult consent' do
      expect do
        complete_last_page(with_adult_consent: true)
      end.to change { Person.count }.by(1)
    end

    it 'can still use step navigator' do
      complete_last_page(with_adult_consent: false)
      click_on 'Personendaten'
      click_on 'Weiter'
      expect(page).to have_css 'li.active', text: 'Familienmitglieder'
      expect(page).not_to have_css('.alert-danger', text: 'Bestätigung des Einverständnisses der Erziehungsberechtigten')
    end
  end

  describe 'with section privacy policy' do
    before do
      file = Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png')
      image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, 'rb'),
                                                     filename: 'logo.png',
                                                     content_type: 'image/png').signed_id
      group.layer_group.update!(privacy_policy: image)
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on 'Weiter als Einzelmitglied', match: :first
    end

    it 'fails if section policy is not accepted' do
      expect do
        complete_last_page
      end.not_to change { Person.count }
      expect(page).to have_text 'Sektionsstatuten muss akzeptiert werden'
    end

    it 'sets privacy policy accepted' do
      expect do
        complete_last_page do
          check 'Ich habe die Sektionsstatuten gelesen und stimme diesen zu'
        end
      end.to change { Person.count }.by(1)
      person = Person.find_by(email: 'max.muster@hitobito.example.com')
      expect(person.privacy_policy_accepted).to eq true
    end
  end

  describe 'document links' do
    it 'should open privacy policy in new tab' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on 'Weiter als Einzelmitglied', match: :first

      expect(page).to have_link('Statuten', target: '_blank')
      expect(page).to have_link('Beitragsreglement', target: '_blank')
      expect(page).to have_link('Datenschutzerklärung', target: '_blank')
    end
  end
end
