# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event_level model", js: true do
  let(:admin) { people(:admin) }

  before { sign_in(admin) }

  it "can create edit and destroy Kursstufe" do
    sign_in(admin)
    visit root_path

    click_on "Einstellungen"
    click_on "Kursstufen"
    click_on "Erstellen"

    fill_in "Code", with: "1"
    fill_in "Bezeichnung", with: "A - dummy"
    fill_in "Schwierigkeitsgrad", with: "20"
    click_on "Speichern"
    expect(page).to have_css(".alert-success", text: "A - dummy wurde erfolgreich erstellt.")

    within("tbody tr:first-child") { click_on "Bearbeiten" }
    fill_in "Bezeichnung", with: "Z - update"
    click_on "Speichern"
    expect(page).to have_css(".alert-success", text: "Z - update wurde erfolgreich aktualisiert.")

    within("tbody tr:last-child") { click_on "Löschen" }
    accept_alert
    expect(page).to have_css(".alert-success", text: "Kursstufe Z - update wurde erfolgreich gelöscht.")
  end
end
