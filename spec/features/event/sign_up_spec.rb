require 'spec_helper'

describe 'Event Signup', :js do

  let(:admin) { people(:admin) }
  let(:root) { groups(:root) }
  before { sign_in(admin) }

  def complete_contact_data
    choose 'Mann'
    fill_in 'Strasse und Nr.', with: 'Musterplatz'
    fill_in 'Geburtstag', with: '01.01.1980'
    fill_in 'Telefon', with: '+41 79 123 45 56'
    fill_in 'event_participation_contact_data_zip_code', with: '8000'
    fill_in 'event_participation_contact_data_town', with: 'Zürich'
    find(:label, "Land").click
    find(:option, text: "Vereinigte Staaten").click
  end

  context 'event' do
    let(:group) { groups(:geschaeftsstelle) }
    let(:event) { Fabricate(:event, groups: [group]) }

    it 'has two step wizard' do
      visit group_event_path(group_id: group, id: event.id)
      click_on 'Anmelden'
      expect(page).to have_css '.stepwizard-step', count: 2
      complete_contact_data
      first(:button, 'Weiter').click
      click_on 'Anmelden'
      expect(page).to have_content 'Teilnahme von Anna Admin in Eventus wurde erfolgreich erstellt'
      expect(admin.reload.address).to eq 'Musterplatz'
      expect(admin.gender).to eq 'm'
      expect(admin.zip_code).to eq '8000'
      expect(admin.town).to eq 'Zürich'
      expect(admin.country).to eq 'US'
      expect(admin.birthday).to eq Date.new(1980, 1, 1)
      expect(admin.phone_numbers.first.number).to eq '+41 79 123 45 56'
      expect(admin.phone_numbers.first.label).to eq 'Mobile'
    end
  end

  context 'course' do
    let(:group) { groups(:root) }
    let(:event) { Fabricate(:sac_open_course, groups: [group], state: :application_open) }

    it 'has two step wizard' do
      visit group_event_path(group_id: group, id: event.id)
      click_on 'Anmelden'
      expect(page).to have_css '.stepwizard-step', count: 2
      complete_contact_data
      first(:button, 'Weiter').click
      click_on 'Anmelden'
      expect(page).to have_content 'Es wurde eine Voranmeldung für Teilnahme'
    end

    context 'with role Mitglied' do
      before do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: groups(:bluemlisalp_mitglieder), person: admin)
      end

      it 'has three step wizard with subsidy checkbox' do
        visit group_event_path(group_id: group, id: event.id)
        click_on 'Anmelden'
        expect(page).to have_css '.stepwizard-step', count: 3
        expect(page).to have_css '.stepwizard-step.is-current', text: 'Kontaktangaben'
        complete_contact_data
        first(:button, 'Weiter').click
        expect(page).to have_css '.stepwizard-step.is-current', text: 'Anmeldung'
        first(:button, 'Weiter').click
        expect(page).to have_css '.stepwizard-step.is-current', text: 'Subventionsbeitrag'
        expect(page).not_to have_text '- Subvention'
        check 'Subventionierten Preis von CHF 620 beantragen'
        expect(page).to have_text '- Subvention'
        uncheck 'Subventionierten Preis von CHF 620 beantragen'
        expect(page).not_to have_text '- Subvention'
        click_on 'Anmelden'
        expect(page).to have_content 'Es wurde eine Voranmeldung für Teilnahme'
      end

      it 'rerenders in correct layout when form is invalid' do
        visit group_event_path(group_id: group, id: event.id)
        click_on 'Anmelden'
        first(:button, 'Weiter').click
        expect(page).to have_css '.stepwizard-step', count: 3
        expect(page).to have_text 'PLZ muss ausgefüllt werden'
        expect(page).to have_css 'h2.card-title', text: 'Zusammenfassung'
      end
    end
  end
end
