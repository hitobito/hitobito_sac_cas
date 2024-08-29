# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe HouseholdsController, js: true do
  let(:person) { people(:familienmitglied) }
  let(:mitglied) { people(:mitglied) }
  let(:household) { Household.new(person) }

  before do 
    sign_in(person)
    visit edit_group_person_household_path(groups(:top_group).id, person.id)
  end

  it "can add person to household with id" do
    fill_in "household_add-ts-control", with: "600001"
    find("span.highlight", text: "Edmund").click
    expect do
      click_on "Speichern"
      expect(page).to have_text "Haushalt wurde erfolgreich aktualisiert."
    end.to change { household.reload.members.count }.by(1)
  end

  it "can add person to household with birth year" do
    fill_in "household_add-ts-control", with: "2000"
    find("span.highlight", text: "Edmund").click
    expect do
      click_on "Speichern"
      expect(page).to have_text "Haushalt wurde erfolgreich aktualisiert."
    end.to change { household.reload.members.count }.by(1)
  end
end
