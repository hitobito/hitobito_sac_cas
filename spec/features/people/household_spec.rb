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
    sign_in(people(:admin))
    visit edit_group_person_household_path(group_id: groups(:bluemlisalp).id, person_id: person.id)
  end

  it "can add person to household with id" do
    fill_in "household_add-ts-control", with: "600001"
    expect(page).to have_css("div.option", text: "Edmund Hillary, Neu Carlscheid (2000; 600001)")
  end

  it "can add person to household with birth year" do
    fill_in "household_add-ts-control", with: "2000"
    expect(page).to have_css("div.option", text: "Edmund Hillary, Neu Carlscheid (2000; 600001)")
  end
end
