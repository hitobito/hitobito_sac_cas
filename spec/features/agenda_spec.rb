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

  it "auto-submits on every filter change, with the search button kept but visually hidden" do
    expect(page).to have_button("Suchen", visible: :all)
    expect(page).not_to have_button("Suchen", visible: true)

    click_button "Zielgruppe"
    check "Kinder (KiBe)"

    expect(page).to have_text(tour.name)
  end

  describe "filtering" do
    it "keeps the tour when the filters still match" do
      find_field("filters_date_range_until").set("01.01.2027").send_keys(:tab)

      expect(page).to have_text(tour.name)
      expect(page).to have_text("1 Tour gefunden")
    end

    it "auto-submits when a date is picked from the calendar, without an explicit submit" do
      # Starts from "since"'s server-rendered value (today = 01.01.2026, from
      # the travel_to above) rather than the browser's own real wall-clock
      # date, which jQuery UI's datepicker would otherwise default to on an
      # empty field - so this stays deterministic regardless of when the
      # spec actually runs.
      find_field("filters_date_range_since").click
      within(".ui-datepicker") do
        find(".ui-datepicker-next").click
        click_on "5"
      end

      expect(find_field("filters_date_range_since").value).to eq "05.02.2026"
      expect(page).not_to have_text(tour.name)
      expect(page).to have_text("0 Touren gefunden")
    end
  end

  describe "resetting filters" do
    it "restores the full result list via the active-filter-chips reset link" do
      click_button "Zielgruppe"
      check "Jugend (JO)"

      expect(page).not_to have_text(tour.name)

      click_link "Alle Filter zurücksetzen"

      expect(page).to have_text(tour.name)
      expect(page).to have_text("1 Tour gefunden")
    end

    it "does a full page reload, so the filter checkbox itself is unchecked too" do
      click_button "Zielgruppe"
      check "Jugend (JO)"
      click_button "Zielgruppe" # close
      expect(page).to have_text("0 Touren gefunden")

      click_link "Alle Filter zurücksetzen"
      expect(page).to have_text("1 Tour gefunden")

      expect(find_field("Jugend (JO)", visible: :all)).not_to be_checked
    end
  end

  describe "no results" do
    it "shows a no-results box with a reset button once the filters match nothing, " \
      "and resetting via it restores the full result list" do
      click_button "Zielgruppe"
      check "Jugend (JO)"

      expect(page).to have_css(".agenda-no-results", text: "Keine Anlässe gefunden")
      expect(page).to have_text("Passe deine Filter an oder setze sie zurück.")
      expect(page).not_to have_text(tour.name)

      click_link "Filter zurücksetzen"

      expect(page).to have_text(tour.name)
      expect(page).to have_text("1 Tour gefunden")
      expect(page).not_to have_css(".agenda-no-results")
    end
  end

  describe "target group filter" do
    it "shows a selected-count badge and filters tours by the checked target group" do
      click_button "Zielgruppe"
      check "Kinder (KiBe)"

      expect(page).to have_button("Zielgruppe", text: "1")
      expect(page).to have_text(tour.name)
    end

    it "excludes the tour once no checked target group matches" do
      click_button "Zielgruppe"
      check "Jugend (JO)"

      expect(page).not_to have_text(tour.name)
      expect(page).to have_text("0 Touren gefunden")
    end
  end

  describe "fitness requirement filter" do
    it "filters tours by the checked fitness requirement" do
      click_button "Kondition"
      check "B - wenig anstrengend"

      expect(page).to have_text(tour.name)
    end
  end

  describe "activities filter" do
    it "reveals the checked activity's technical requirement grades as chips and filters by one" do
      click_button "Aktivitäten"
      check "Wanderweg"

      expect(page).to have_button("T3")

      # Scoped: skihochtour/snowboardhochtour reuse the same fixture technical
      # requirement, so their (unchecked, hidden) chips also render a "T3" -
      # click within Wanderweg's own chip row to stay unambiguous.
      within("div[data-activity-id='#{event_activities(:wanderweg).id}']") { click_button "T3" }

      expect(page).to have_text(tour.name)
    end

    it "hides the chips again once the activity is unchecked" do
      click_button "Aktivitäten"
      check "Wanderweg"
      expect(page).to have_button("T3", visible: true)

      uncheck "Wanderweg"

      expect(page).to have_button("T3", visible: false)
    end

    it "selecting the main activity checkbox selects all of its children" do
      click_button "Aktivitäten"
      check "Wandern"

      expect(page).to have_checked_field("Wanderweg")
      expect(page).to have_checked_field("Bergtour")
      expect(page).to have_checked_field("Schneeschuhwandern")
    end

    it "still shows the swatch and bold label for a main activity whose only " \
      "child shares its label, but keeps the checkbox and chips wired to that activity" do
      solo = Fabricate(:event_activity, label: "Sololauf", color: "#123456")
      child = Fabricate(:event_activity, label: "Sololauf", parent: solo)
      child.update!(technical_requirement: event_technical_requirements(:wandern))

      visit agenda_index_path(group_id: group.id)
      click_button "Aktivitäten"

      group_fieldset = find(".agenda-filter-group", text: "Sololauf")
      expect(group_fieldset).to have_css(".agenda-activity-swatch")
      expect(group_fieldset).to have_css(".form-check-label.fw-bold", text: "Sololauf")

      check "Sololauf"

      expect(page).to have_button("T1", visible: true)
    end
  end

  describe "full-text search" do
    it "keeps the tour when the search term matches its name" do
      find("#filters_full_text_q").set("Bundstock")

      expect(page).to have_text(tour.name)
      expect(page).to have_text("1 Tour gefunden")
    end

    it "excludes the tour once the search term matches nothing" do
      find("#filters_full_text_q").set("Matterhorn")

      expect(page).not_to have_text(tour.name)
      expect(page).to have_text("0 Touren gefunden")
    end

    it "ignores a query shorter than the minimum search length" do
      find("#filters_full_text_q").set("Bu")

      expect(page).to have_text(tour.name)
      expect(page).to have_text("1 Tour gefunden")
    end

    it "shows the term in quotes as a removable chip, and removing it clears the search" do
      find("#filters_full_text_q").set("Bundstock")

      expect(page).to have_css(".agenda-filter-chip", text: '"Bundstock"')

      find(".agenda-filter-chip", text: '"Bundstock"').click

      expect(page).not_to have_css(".agenda-filter-chip", text: '"Bundstock"')
      expect(find("#filters_full_text_q").value).to be_blank
    end
  end

  describe "active filter chips" do
    it "shows a removable chip for an applied filter, and removing it drops that filter" do
      click_button "Zielgruppe"
      check "Kinder (KiBe)"
      click_button "Zielgruppe" # close the dropdown so it doesn't overlap the chip below

      expect(page).to have_css(".agenda-filter-chip", text: "Kinder (KiBe)")

      find(".agenda-filter-chip", text: "Kinder (KiBe)").click

      expect(page).not_to have_css(".agenda-filter-chip", text: "Kinder (KiBe)")
      expect(page).not_to have_checked_field("Kinder (KiBe)")
    end

    it "does a full page reload, so the filter checkbox itself is unchecked too" do
      # Kept as a separate check from the one above: with the dropdown
      # closed (as it has to be, to click the chip), Capybara's default
      # "visible" field matcher can't see the checkbox at all, checked or
      # not - so `visible: :all` is needed to actually assert on it, and
      # "Jugend (JO)" (which excludes the tour) rather than "Kinder (KiBe)"
      # (which doesn't) gives a reliable "wait for the reload" signal via
      # the result count, instead of racing a text that's already true
      # beforehand.
      click_button "Zielgruppe"
      check "Jugend (JO)"
      click_button "Zielgruppe" # close
      expect(page).to have_text("0 Touren gefunden")

      find(".agenda-filter-chip", text: "Jugend (JO)").click
      expect(page).to have_text("1 Tour gefunden")

      expect(find_field("Jugend (JO)", visible: :all)).not_to be_checked
    end
  end
end
