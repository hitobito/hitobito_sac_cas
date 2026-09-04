# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/activities", js: true do
  let(:admin) { people(:admin) }

  before { sign_in(admin) }

  it "toggles color, icon and technical requirement fields based on parent selection" do
    visit new_event_activity_path

    expect(page).to have_field "Farbe", visible: true
    expect(page).to have_field "Icon hochladen", type: "file", visible: true
    expect(page).to have_select "Technische Anforderung", visible: false

    select "Klettern", from: "Übergeordnete Aktivität"

    expect(page).to have_field "Farbe", visible: false
    expect(page).to have_field "Icon hochladen", type: "file", visible: false
    expect(page).to have_select "Technische Anforderung", visible: true
  end

  it "uploads an icon for a main activity" do
    visit edit_event_activity_path(event_activities(:klettern))

    attach_file "Icon hochladen", file_fixture("icon.svg")
    click_button "Speichern"

    expect(page).to have_content "Aktivität Klettern wurde erfolgreich aktualisiert"
    expect(event_activities(:klettern).reload.icon).to be_attached

    visit edit_event_activity_path(event_activities(:klettern))
    expect(page).to have_css "svg[stroke='currentColor']"
    expect(page).to have_field "Aktuelles Icon entfernen"
  end
end
