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
  end

  describe "filtering" do
    it "keeps the tour when the filters still match" do
      fill_in "filters_date_range_until", with: "01.01.2027"

      click_button "Suchen"

      expect(page).to have_text(tour.name)
      expect(page).to have_text("1 Tour gefunden")
    end
  end

  describe "resetting filters" do
    before do
      fill_in "filters_date_range_until", with: "01.01.2027"
      click_button "Suchen"

      click_button "Filter zurücksetzen"
    end

    it "restores the default filter values" do
      expect(find_field("filters_date_range_since").value).to eq "01.01.2026"
      expect(find_field("filters_date_range_until").value).to be_blank
    end
  end

  describe "target group filter" do
    it "shows a selected-count badge and filters tours by the checked target group" do
      click_button "Zielgruppe"
      check "Kinder (KiBe)"

      expect(page).to have_button("Zielgruppe", text: "1")

      click_button "Suchen"

      expect(page).to have_text(tour.name)
    end

    it "excludes the tour once no checked target group matches" do
      click_button "Zielgruppe"
      check "Jugend (JO)"
      click_button "Suchen"

      expect(page).not_to have_text(tour.name)
      expect(page).to have_text("0 Touren gefunden")
    end
  end

  describe "fitness requirement filter" do
    it "filters tours by the checked fitness requirement" do
      click_button "Kondition"
      check "B - wenig anstrengend"
      click_button "Suchen"

      expect(page).to have_text(tour.name)
    end
  end

  describe "activities filter" do
    it "reveals the checked activity's technical requirement as a chip and filters by it" do
      click_button "Aktivitäten"
      check "Wanderweg"

      expect(page).to have_button("Wanderskala")

      click_button "Wanderskala"
      click_button "Suchen"

      expect(page).to have_text(tour.name)
    end

    it "hides the chip again once the activity is unchecked" do
      click_button "Aktivitäten"
      check "Wanderweg"
      expect(page).to have_button("Wanderskala", visible: true)

      uncheck "Wanderweg"

      expect(page).to have_button("Wanderskala", visible: false)
    end

    it "selecting the discipline checkbox selects all of its activities" do
      click_button "Aktivitäten"
      check "Wandern"

      expect(page).to have_checked_field("Wanderweg")
      expect(page).to have_checked_field("Bergtour")
      expect(page).to have_checked_field("Schneeschuhwandern")
    end
  end

  describe "active filter chips" do
    it "shows a removable chip for an applied filter, and removing it drops that filter" do
      click_button "Zielgruppe"
      check "Kinder (KiBe)"
      click_button "Suchen"

      expect(page).to have_css(".agenda-filter-chip", text: "Kinder (KiBe)")

      find(".agenda-filter-chip", text: "Kinder (KiBe)").click

      expect(page).not_to have_css(".agenda-filter-chip", text: "Kinder (KiBe)")
      expect(page).not_to have_checked_field("Kinder (KiBe)")
    end
  end
end
