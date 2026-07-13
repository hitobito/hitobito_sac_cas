# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "agenda page", js: true do
  let(:group) { groups(:bluemlisalp) }
  let(:tour) { events(:section_tour) }

  around do |example|
    travel_to(Time.zone.local(2026, 1, 1)) { example.run }
  end

  before do
    tour.update_columns(
      state: :published,
      globally_visible: true,
      display_booking_info: true,
      application_opening_at: Date.new(2025, 12, 1),
      application_closing_at: Date.new(2026, 2, 1)
    )
    tour.dates.update_all(start_at: Date.new(2026, 2, 1))

    visit agenda_index_path(group_id: group.id)
  end

  it "shows the tour and the default filter values" do
    expect(page).to have_text(tour.name)
    expect(page).to have_text("1 Tour gefunden")

    expect(find_field("filters_date_range_since").value).to eq "01.01.2026"
    expect(find_field("filters_date_range_until").value).to be_blank
    expect(page).to have_checked_field("filters_application_open_value_0")
    expect(page).to have_checked_field("filters_places_available_value_0")
  end

  describe "filtering" do
    it "keeps the tour when the filters still match" do
      fill_in "filters_date_range_until", with: "01.01.2027"
      choose "filters_application_open_value_1"
      choose "filters_places_available_value_1"

      click_button "Suchen"

      expect(page).to have_text(tour.name)
      expect(page).to have_text("1 Tour gefunden")
    end

    it "excludes the tour once the application window filter no longer matches" do
      tour.update!(
        application_opening_at: Date.new(2025, 11, 1),
        application_closing_at: Date.new(2025, 12, 1)
      )

      choose "filters_application_open_value_1"
      click_button "Suchen"

      expect(page).not_to have_text(tour.name)
      expect(page).to have_text("0 Touren gefunden")
    end
  end

  describe "resetting filters" do
    before do
      fill_in "filters_date_range_until", with: "01.01.2027"
      choose "filters_application_open_value_1"
      choose "filters_places_available_value_1"
      click_button "Suchen"

      click_button "Filter zurücksetzen"
    end

    it "restores the default filter values" do
      expect(find_field("filters_date_range_since").value).to eq "01.01.2026"
      expect(find_field("filters_date_range_until").value).to be_blank
      expect(page).to have_checked_field("filters_application_open_value_0")
      expect(page).to have_checked_field("filters_places_available_value_0")
    end
  end
end
