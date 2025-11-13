# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe :"event/kinds", js: true do
  before { sign_in(people(:admin)) }

  it "changing event updates cost fields if they are blank" do
    visit new_event_kind_path
    expect(page).to have_select "Kostenstelle", selected: "Bitte auswählen"
    expect(page).to have_select "Kostenträger", selected: "Bitte auswählen"
    select "Ski Technik Kurs"
    expect(page).to have_select "Kostenstelle", selected: "kurs-1 - Kurse"
    expect(page).to have_select "Kostenträger", selected: "ski-1 - Ski Technik"
  end

  context "overriding behaviour" do
    let!(:center) { Fabricate(:cost_center, code: 1, label: "center") }
    let!(:unit) { Fabricate(:cost_unit, code: 2, label: "unit") }

    it "does only override non selected values" do
      visit new_event_kind_path
      select "1 - center"
      select "Ski Technik Kurs"
      expect(page).to have_select "Kostenstelle", selected: "1 - center"
      expect(page).to have_select "Kostenträger", selected: "ski-1 - Ski Technik"
    end

    it "supports hard override via button" do
      visit new_event_kind_path
      select "1 - center"
      select "2 - unit"
      select "Ski Technik Kurs"
      click_on "Werte übernehmen"
      expect(page).to have_select "Kostenstelle", selected: "kurs-1 - Kurse"
      expect(page).to have_select "Kostenträger", selected: "ski-1 - Ski Technik"
    end
  end

  context "push down field" do
    let(:kind) { event_kinds(:ski_course) }

    it "asks for confirmation and shows flash notice" do
      kind.update!(minimum_participants: 10)
      visit edit_event_kind_path(id: kind.id)
      accept_confirm do
        find("#event_kind_minimum_participants + .form-text a").click
      end
      expect(page).to have_selector(".alert-success",
        text: "Minimale Teilnehmerzahl wurde auf alle aktiven Kurse übertragen.")
      expect(events(:application_closed).minimum_participants).to eq(10)
    end

    it "is prevented if select is changed" do
      visit edit_event_kind_path(id: kind.id)
      select("board-2", from: "event_kind_cost_unit_id")
      accept_alert(/nicht gespeichert/) do
        find("#event_kind_cost_unit_id + .form-text a").click
      end
    end

    it "is prevented if input is changed" do
      visit edit_event_kind_path(id: kind.id)
      fill_in "event_kind_minimum_participants", with: "5"
      accept_alert(/nicht gespeichert/) do
        find("#event_kind_minimum_participants + .form-text a").click
      end
    end

    it "is prevented if textarea is changed" do
      visit edit_event_kind_path(id: kind.id)
      fill_in "event_kind_application_conditions", with: "Skifahren"
      accept_alert(/nicht gespeichert/) do
        find("#event_kind_application_conditions").ancestor(".labeled").find(".form-text a").click
      end
    end

    it "is prevented if checkbox is changed" do
      visit edit_event_kind_path(id: kind.id)
      uncheck "event_kind_reserve_accommodation"
      accept_alert(/nicht gespeichert/) do
        find("#event_kind_reserve_accommodation")
          .first(:xpath, ".//..")
          .first(:xpath, ".//..")
          .find(".form-text a").click
      end
    end
  end
end
