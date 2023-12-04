# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


require 'spec_helper'

describe :self_registration, js: true do
  Capybara.default_max_wait_time = 0.5

  class Group::SelfRegistrationGroup < Group
    self.layer = true

    class ReadOnly < ::Role
      self.permissions = [:group_read]
    end

    roles ReadOnly
  end

  let(:group) do
    Group::SelfRegistrationGroup.create!(name: 'Self-Registration Group')
  end

  let(:self_registration_role) { group.decorate.allowed_roles_for_self_registration.first }

  before do
    group.self_registration_role_type = self_registration_role
    group.save!

    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  def complete_main_person_form
    fill_in 'Vorname', with: 'Max'
    fill_in 'Nachname', with: 'Muster'
    fill_in 'Adresse', with: 'Musterplatz'
    fill_in 'self_registration_main_person_attributes_zip_code', with: '8000'
    fill_in 'self_registration_main_person_attributes_town', with: 'Zürich'
    fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'
    fill_in 'Geburtstag', with: '01.01.1980'
    yield if block_given?
    click_on 'Weiter'
  end

  describe 'main_person' do
    it 'validates and marks attributes' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form do
        fill_in 'Haupt-E-Mail', with: 'support@hitobito.example.com'
      end
      expect(page).to have_content 'Haupt-E-Mail ist bereits vergeben'
      expect(page).not_to have_link 'Weiter als Einzelmitglied'
    end

    it 'self registers and creates new person' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form do
        choose 'männlich'
        country_selector = "#person_country"
        find("#{country_selector}").click
        find("#{country_selector} div.ts-dropdown-content div[role='option']", text: 'Vereinigte Staaten').click
      end
      click_on 'Weiter als Einzelmitglied'

      expect do
        click_on 'Registrieren'
      end.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(page).to have_text('Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.')

      person = Person.find_by(email: 'max.muster@hitobito.example.com')
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

    describe 'with privacy policy' do
      before do

        file = Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png')
        image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, 'rb'),
                                                       filename: 'logo.png',
                                                       content_type: 'image/png').signed_id
        group.layer_group.update(privacy_policy: image)
        visit group_self_registration_path(group_id: group)
      end

      it 'sets privacy policy accepted' do
        complete_main_person_form
        click_on 'Weiter als Einzelmitglied'
        check 'Ich erkläre mich mit den folgenden Bestimmungen einverstanden:'

        expect do
          click_on 'Registrieren'
        end.to change { Person.count }.by(1)
        person = Person.find_by(email: 'max.muster@hitobito.example.com')
        expect(person.privacy_policy_accepted).to eq true
      end
    end
  end

  describe 'household' do
    it 'can create several people in same household' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form

      expect(page).to have_content 'Hier kannst du eine Famlienmitgliedschaft wählen.'

      click_on 'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(1)' do
        fill_in 'Vorname', with: 'Maxine'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1981'
        fill_in 'Haupt-E-Mail', with: 'maxine.muster@hitobito.example.com'
        choose 'weiblich'
      end
      click_on  'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(2)' do
        fill_in 'Vorname', with: 'Maxi'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.2012'
        fill_in 'Haupt-E-Mail', with: 'maxi.muster@hitobito.example.com'
        choose 'andere'
      end
      find('.btn-toolbar.bottom .btn-group button[type="submit"]', text: 'Weiter als Familienmitgliedschaft').click

      expect do
        click_on 'Registrieren'
      end.to change { Person.count }.by(3)
        .and change { Role.count }.by(3)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(page).to have_text('Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.')

      people = Person.where(last_name: 'Muster')
      expect(people).to have(3).items
      expect(people.pluck(:household_key).compact.uniq).to have(1).item
    end

    it 'can add and remove housemate' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on  'Eintrag hinzufügen'

      within '#housemates_fields .fields:nth-child(1)' do
        fill_in 'Vorname', with: 'Maxine'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.1981'
        fill_in 'Haupt-E-Mail', with: 'maxine.muster@hitobito.example.com'
        choose 'weiblich'
      end

      click_on  'Eintrag hinzufügen'
      within '#housemates_fields .fields:nth-child(2)' do
        fill_in 'Vorname', with: 'Maxi'
        fill_in 'Nachname', with: 'Muster'
        fill_in 'Geburtstag', with: '01.01.2012'
        fill_in 'Haupt-E-Mail', with: 'maxi.muster@hitobito.example.com'
        choose 'andere'
      end

      within '#housemates_fields .fields:nth-child(1)' do
        click_on 'Entfernen'
      end
      click_on 'Weiter als Familienmitgliedschaft'

      expect do
        click_on 'Registrieren'
      end.to change { Person.count }.by(2)
      people = Person.where(last_name: 'Muster')
      expect(people).to have(2).items
      expect(people.pluck(:first_name)).to match_array(%w[Max Maxi])
    end

    it 'validates emails within household' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
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

    it 'validates birthday within household' do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on  'Eintrag hinzufügen'

      fill_in 'Vorname', with: 'Maxi'
      fill_in 'Nachname', with: 'Muster'
      fill_in 'Haupt-E-Mail', with: 'maxi.muster@hitobito.example.com'
      choose 'weiblich'
      click_on 'Weiter als Familienmitgliedschaft'
      expect(page).to have_content 'Geburtstag muss ausgefüllt werden'
    end


    context 'bluemlisalp_neuanmeldungen_sektion' do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

      it 'validates birthday is valid' do
        visit group_self_registration_path(group_id: group)
        complete_main_person_form
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
