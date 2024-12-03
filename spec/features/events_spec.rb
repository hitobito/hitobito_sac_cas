# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe :events, js: true do
  before { sign_in(people(:admin)) }

  let(:group) { groups(:root) }
  let(:kind) { event_kinds(:ski_course) }
  let(:kind_attrs) {
    {
      kind_category: event_kind_categories(:ski_course),
      reserve_accommodation: false,
      accommodation: :hut,
      season: :summer,
      minimum_age: 18,
      training_days: 10,
      minimum_participants: 3,
      maximum_participants: 10,
      application_conditions: "Vorraussetzungen sind .."
    }
  }

  def click_tab(name)
    within(".nav-tabs") do
      click_on name
    end
    expect(page).to have_css(".nav-tabs .nav-link.active", text: name)
  end

  context "prices" do
    let(:event) { events(:top_course) }

    # TODO: Workaround for hitobito_youth changes. See
    # https://github.com/hitobito/hitobito_youth/issues/58 for context
    before { event.init_questions(disclosure: :hidden) }

    it "allows to fill in prices" do
      expect(event).to be_valid
      visit edit_group_event_path(group_id: group.id, id: event.id)
      click_tab "Preise"

      fill_in "Mitgliederpreis", with: "100.05"
      fill_in "Normalpreis", with: "100.15"
      fill_in "Subventionierter Preis", with: "90.05"
      fill_in "J&S A-Mitgliederpreis", with: "89.05"
      fill_in "J&S A-Normalpreis", with: "90.15"
      fill_in "J&S P-Mitgliederpreis", with: "82.05"
      fill_in "J&S P-Normalpreis", with: "89.15"

      expect do
        click_button("Speichern", match: :first)
        expect(page).to have_content(/Anlass .* wurde erfolgreich aktualisiert./)
        event.reload
      end
        .to change { event.price_member }.to(100.05)
        .and change { event.price_regular }.to(100.15)
        .and change { event.price_subsidized }.to(90.05)
        .and change { event.price_js_active_member }.to(89.05)
        .and change { event.price_js_active_regular }.to(90.15)
        .and change { event.price_js_passive_member }.to(82.05)
        .and change { event.price_js_passive_regular }.to(89.15)

      price_selector = "#main article"
      find(price_selector).assert_text("Mitgliederpreis CHF 100.05")
      find(price_selector).assert_text("Normalpreis CHF 100.15")
      find(price_selector).assert_text("Subventionierter Preis CHF 90.05")
      find(price_selector).assert_text("J&S A-Mitgliederpreis CHF 89.05")
      find(price_selector).assert_text("J&S A-Normalpreis CHF 90.15")
      find(price_selector).assert_text("J&S P-Mitgliederpreis CHF 82.05")
      find(price_selector).assert_text("J&S P-Normalpreis CHF 89.15")
    end
  end

  describe "attendents" do
    let(:event) { events(:top_course) }

    it "Allows to add new leaders" do
      visit group_event_participations_path(group_id: group.id, event_id: event.id)
      click_on "Person hinzufügen"
      click_on "Kursleitung"
      expect(page).to have_title(/Kursleitung erstellen/)
      expect(page).to have_field("Selbständig erwerbend")

      fill_in "Person", with: "Admin"
      find('ul[role="listbox"] li[role="option"]').click
      page.check "Selbständig erwerbend"
      expect do
        click_on "Speichern"
        expect(page).to have_content("Rolle Kursleitung für Anna Admin wurde erfolgreich erstellt")
      end
        .to change(Event::Participation, :count).by(1)
      expect(page).to have_content("Anmeldung von Anna Admin bearbeiten")
      click_on "Speichern"
      expect(page).to have_content("Teilnahme von Anna Admin in Tourenleiter/in 1 Sommer wurde erfolgreich aktualisiert.")
      expect(page).to have_content("Kursleitung selbständig erwerbend")
    end
  end

  context "overriding behaviour" do
    before do
      kind.attributes = kind_attrs
      kind.save!
    end

    it "selecting kind overrides default values" do
      visit new_group_event_path(group_id: group.id, event: {type: "Event::Course"})
      expect(page).to have_checked_field "Unterkunft reservieren durch SAC"
      expect(page).to have_select "Unterkunft", selected: "ohne Übernachtung"
      expect(page).to have_field "Ausbildungstage", with: ""
      expect(page).to have_select "Kostenstelle", selected: "(keine)"
      expect(page).to have_select "Kostenträger", selected: "(keine)"

      click_tab "Daten"
      expect(page).to have_select "Saison", selected: "(keine)"
      expect(page).to have_select "Kursbegin", selected: "(keine)"

      click_tab "Anmeldung"
      expect(page).to have_field "Maximale Teilnehmerzahl", with: ""
      expect(page).to have_field "Minimale Teilnehmerzahl", with: ""
      expect(page).to have_field "Mindestalter", with: ""
      expect(page).to have_field "Aufnahmebedingungen", with: ""

      click_tab "Allgemein"
      expect(page).to have_field "Ausbildungstage", with: ""
      select "DMY (Dummy)"

      expect(page).to have_unchecked_field "Unterkunft reservieren durch SAC"
      expect(page).to have_select "Unterkunft", selected: "Hütte"
      expect(page).to have_field "Ausbildungstage", with: "10.0"
      expect(page).to have_select "Kostenstelle", selected: "kurs-1 - Kurse"
      expect(page).to have_select "Kostenträger", selected: "ski-1 - Ski Technik"

      click_tab "Daten"
      expect(page).to have_select "Saison", selected: "Sommer"
      click_tab "Anmeldung"
      expect(page).to have_field "Maximale Teilnehmerzahl", with: "10"
      expect(page).to have_field "Minimale Teilnehmerzahl", with: "3"
      expect(page).to have_field "Mindestalter", with: "18"
      expect(page).to have_field "Aufnahmebedingungen", with: "Vorraussetzungen sind .."
    end

    it "selecting kind leaves previous non default values untouched" do
      cost_unit = Fabricate(:cost_unit)
      cost_center = Fabricate(:cost_center)
      visit new_group_event_path(group_id: group.id, event: {type: "Event::Course"})
      check "Unterkunft reservieren durch SAC"
      select "Pension/Berggasthaus"
      fill_in "Ausbildungstage", with: 2
      select cost_center.to_s
      select cost_unit.to_s

      click_tab "Daten"
      select "Winter"

      click_tab "Anmeldung"
      fill_in "Maximale Teilnehmerzahl", with: "10"
      fill_in "Minimale Teilnehmerzahl", with: "5"
      fill_in "Mindestalter", with: "12"
      fill_in "Aufnahmebedingungen", with: "keine Vorraussetzungen"

      click_tab "Allgemein"
      select "DMY (Dummy)"

      # Checkbox gets resetted as checked is the default state
      expect(page).to have_unchecked_field "Unterkunft reservieren durch SAC"
      expect(page).to have_select "Unterkunft", selected: "Pension/Berggasthaus"
      expect(page).to have_field "Ausbildungstage", with: "2"
      expect(page).to have_select "Kostenstelle", selected: cost_center.to_s
      expect(page).to have_select "Kostenträger", selected: cost_unit.to_s

      click_tab "Daten"
      expect(page).to have_select "Saison", selected: "Winter"

      click_tab "Anmeldung"
      expect(page).to have_field "Maximale Teilnehmerzahl", with: "10"
      expect(page).to have_field "Minimale Teilnehmerzahl", with: "5"
      expect(page).to have_field "Mindestalter", with: "12"
      expect(page).to have_field "Aufnahmebedingungen", with: "keine Vorraussetzungen"
    end

    it "overrides previous values when action is forced via explicit click" do
      cost_unit = Fabricate(:cost_unit)
      cost_center = Fabricate(:cost_center)
      visit new_group_event_path(group_id: group.id, event: {type: "Event::Course"})
      check "Unterkunft reservieren durch SAC"
      select "Pension/Berggasthaus"
      fill_in "Ausbildungstage", with: 2
      select cost_center.to_s
      select cost_unit.to_s

      click_on "Daten"
      select "Winter"

      click_on "Anmeldung"
      fill_in "Maximale Teilnehmerzahl", with: "5"
      fill_in "Maximale Teilnehmerzahl", with: "1"
      fill_in "Mindestalter", with: "12"
      fill_in "Aufnahmebedingungen", with: "keine Vorraussetzungen"

      click_on "Allgemein"
      select "DMY (Dummy)"
      click_on "Werte übernehmen"

      expect(page).to have_unchecked_field "Unterkunft reservieren durch SAC"
      expect(page).to have_select "Unterkunft", selected: "Hütte"
      expect(page).to have_field "Ausbildungstage", with: "10.0"
      expect(page).to have_select "Kostenstelle", selected: "kurs-1 - Kurse"
      expect(page).to have_select "Kostenträger", selected: "ski-1 - Ski Technik"

      click_on "Daten"
      expect(page).to have_select "Saison", selected: "Sommer"

      click_on "Anmeldung"
      expect(page).to have_field "Maximale Teilnehmerzahl", with: "10"
      expect(page).to have_field "Minimale Teilnehmerzahl", with: "3"
      expect(page).to have_field "Mindestalter", with: "18"
      fill_in "Aufnahmebedingungen", with: "Vorraussetzungen sind .."
    end
  end
end
