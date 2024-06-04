# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


require 'spec_helper'

describe :event_participation, js: true do

  subject { page }

  let(:person) { people(:mitglied) }
  let(:event) { Fabricate(:event, application_opening_at: 5.days.ago, groups: [group]) }
  let(:group) { person.roles.first.group }

  before do
    sign_in(person)
  end
  def complete_contact_data
    choose 'Mann'
    fill_in 'event_participation_contact_data_street', with: 'Musterplatz'
    fill_in 'event_participation_contact_data_housenumber', with: '23'
    fill_in 'Geburtstag', with: '01.01.1980'
    fill_in 'Telefon', with: '+41 79 123 45 56'
    fill_in 'event_participation_contact_data_zip_code', with: '8000'
    fill_in 'event_participation_contact_data_town', with: 'Zürich'
    find(:label, "Land").click
    find(:option, text: "Vereinigte Staaten").click
  end


  it 'creates an event participation' do
    # pending('Event participations are not implemented yet for SAC'); raise NotImplementedError

    visit group_event_path(group_id: group, id: event)

    click_link('Anmelden')

    complete_contact_data
    first(:button, 'Weiter').click

    fill_in('Kommentar', with: 'Wichtige Bemerkungen über meine Teilnahme')

    expect do
      click_button('Anmelden')
      expect(page).to have_text("Teilnahme von #{person.full_name} in #{event.name} wurde " \
                                "erfolgreich erstellt. Bitte überprüfe die Kontaktdaten und " \
                                "passe diese gegebenenfalls an.")
    end.to change { Event::Participation.count }.by(1)

    is_expected.to have_text('Wichtige Bemerkungen über meine Teilnahme')
    is_expected.to have_selector('dt', text: 'Anzahl Mitglieder-Jahre')

    participation = Event::Participation.find_by(event: event, person: person)

    expect(participation).to be_present
  end

  describe 'canceling participation' do
    let(:group) { groups(:root) }
    let(:application) { Fabricate(:event_application, priority_1: event, priority_2: event) }
    let(:participation) { Fabricate(:event_participation, event: event, person: person, application: application) }
    let(:event) { Fabricate(:sac_course, application_opening_at: 5.days.ago, groups: [group], applications_cancelable: true) }

    before do
      participation.update!(state: :assigned)
      event.update(applications_cancelable: true)
      event.dates.first.update_columns(start_at: 2.days.from_now)
    end

    context 'on event' do
      it 'requires a reason when canceling' do
        visit group_event_path(group_id: group, id: event)
        click_button 'Abmelden'
        within('.popover-body') { click_on 'Abmelden' }
        expect( find_field('Begründung').native.attribute('validationMessage')).to eq 'Please fill out this field.'
      end

      it 'can cancel with reason' do
        visit group_event_path(group_id: group, id: event)
        click_button 'Abmelden'
        fill_in 'Begründung', with: 'Krank'
        within('.popover-body') { click_on 'Abmelden' }
        expect(page).not_to have_button 'Abmelden'
        expect(page).not_to have_css('.popover-body')
      end
    end

    context 'on participation' do
      it 'requires a reason when canceling' do
        visit group_event_participation_path(group_id: group, event_id: event, id: participation.id)
        click_button 'Abmelden'
        within('.popover-body') { click_on 'Abmelden' }
        expect( find_field('Begründung').native.attribute('validationMessage')).to eq 'Please fill out this field.'
      end

      it 'can cancel with reason' do
        visit group_event_participation_path(group_id: group, event_id: event, id: participation.id)
        click_button 'Abmelden'
        fill_in 'Begründung', with: 'Krank'
        within('.popover-body') { click_on 'Abmelden' }
        expect(page).not_to have_button 'Abmelden'
        expect(page).not_to have_css('.popover-body')
      end
    end
  end

end
