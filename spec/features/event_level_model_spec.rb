# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'event_level model', js: true do
  let(:admin) { people(:admin) }
  before { sign_in(admin) }

  it "can create edit and destroy Kursstufe" do
    sign_in(admin)
    visit root_path
    click_on 'Einstellungen'
    click_on 'Kursstufen'
    click_on 'Erstellen'
    fill_in 'Code', with: '1'
    fill_in 'Bezeichnung', with: 'dummy'
    fill_in 'Schwierigkeitsgrad', with: '20'
    click_on 'Speichern'
    expect(page).to have_css('.alert-success', text: "dummy wurde erfolgreich erstellt.")

    within("tbody tr:nth-child(1)") { click_on 'Bearbeiten' }
    fill_in 'Bezeichnung', with: 'update'
    click_on 'Speichern'
    expect(page).to have_css('.alert-success', text: "update wurde erfolgreich aktualisiert.")

    within("tbody tr:nth-child(1)") { click_on 'Löschen' }
    accept_alert
    expect(page).to have_css('.alert-success', text: "Kursstufe wurde erfolgreich gelöscht.")
  end
end
