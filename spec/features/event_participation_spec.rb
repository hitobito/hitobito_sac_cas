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

  it 'creates an event participation' do
    pending('Event participations are not implemented yet for SAC'); raise NotImplementedError

    visit group_event_path(group_id: group, id: event)

    click_link('Anmelden')
    binding.pry
    find_all('.btn-toolbar.bottom .btn-group button[type="submit"]').first.click # "Weiter"

    fill_in('Bemerkungen', with: 'Wichtige Bemerkungen über meine Teilnahme')

    expect do
      click_button('Anmelden')
    end.to change { Event::Participation.count }.by(1)

    is_expected.to have_text("Teilnahme von #{person.full_name} in #{event.name} wurde erfolgreich erstellt. Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an.")
    is_expected.to have_text('Wichtige Bemerkungen über meine Teilnahme')

    participation = Event::Participation.find_by(event: event, person: person)

    expect(participation).to be_present
  end

end
