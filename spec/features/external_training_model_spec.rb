# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'external_training model', js: true do
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }
  before { sign_in(admin) }

  it "can create and destroy Externe Ausbildung" do
    sign_in(admin)
    visit history_group_person_path(group_id: mitglieder, id: mitglied)
    click_on 'Erstellen'
    select 'Dummy', from: 'external_training_event_kind_id'
    fill_in 'Name', with: 'Schwimmkurs'
    fill_in 'Anbieter', with: 'Berner Ausbildungszentrum für fortgeschrittene Aquaristikkunst'
    fill_in 'Startdatum', with: '01.03.2024'
    fill_in 'Enddatum', with: '06.03.2024'
    fill_in 'Ausbildungstage', with: '5'
    fill_in 'Link', with: 'https://wasser.example.com'
    fill_in 'Bemerkung', with: 'Bla'
    all('button', text: 'Speichern').first.click

    expect(page).to have_css('.alert-success', text: "Schwimmkurs wurde erfolgreich erstellt.")

    within('#external_trainings') { click_on 'Löschen' }
    accept_alert
    expect(page).to have_css('.alert-success',
text: "Externe Ausbildung Schwimmkurs wurde erfolgreich gelöscht.")
  end

  it "reloads qualification infos", js: true do
    sign_in(admin)
    visit history_group_person_path(group_id: mitglieder, id: mitglied)
    click_on 'Erstellen'
    fill_in 'Name', with: 'Skikurs'
    fill_in 'Startdatum', with: '01.03.2024'
    fill_in 'Enddatum', with: '06.03.2024'
    select 'Dummy', from: 'external_training_event_kind_id'
    expect(page).to have_css 'turbo-frame p', text: 'Verlängert existierende Qualifikation ' \
      'Ski Leiter unmittelbar per 06.03.2024 (letztes Kursdatum).'
    expect(page).to have_select 'external_training_event_kind_id', selected: 'DMY (Dummy)'
    select '(keine)', from: 'external_training_event_kind_id'
    expect(page).not_to have_css 'turbo-frame p'
  end
end
