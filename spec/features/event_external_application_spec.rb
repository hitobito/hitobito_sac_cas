# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


require 'spec_helper'

describe :event_external_application, js: true do
  subject { page }

  let(:event) { Fabricate(:event, application_opening_at: 5.days.ago,
                          external_applications: true, groups: [group]) }
  let(:group) { groups(:root) }

  it 'creates an external event participation' do
    pending('Event participations are not implemented yet for SAC'); raise NotImplementedError

    visit group_public_event_path(group_id: group, id: event)

    find_all('#register_form input#person_email').first.fill_in(with: 'max.muster@hitobito.example.com')

    click_button('Weiter')

    fill_in 'Vorname', with: 'Max'
    fill_in 'Nachname', with: 'Muster'
    fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'

    expect do
      find_all('.btn-toolbar.bottom .btn-group button[type="submit"]').first.click # submit
    end.to change { Person.count }.by(1)

    fill_in('Bemerkungen', with: 'Wichtige Bemerkungen über meine Teilnahme')

    expect do
      click_button('Anmelden')
    end.to change { Event::Participation.count }.by(1)

    person = Person.find_by(email: 'max.muster@hitobito.example.com')
    expect(person).to be_present

    is_expected.to have_text("Teilnahme von #{person.full_name} in #{event.name} wurde erfolgreich erstellt. Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an.")
    is_expected.to have_text('Wichtige Bemerkungen über meine Teilnahme')

  end
end
