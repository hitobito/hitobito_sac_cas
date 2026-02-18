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

  context "event_questions" do
    let(:event) do
      event = Fabricate(:course, kind: event_kinds(:ski_course), groups: [groups(:root)])
      event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
      event
    end

    it "orders event questions alphabetically on edit page" do
      Event::Question.where(event_id: nil).second.update!(question: "Aaa question?")

      visit edit_group_event_path(group_id: group.id, id: event.id)
      click_on "Anmeldeangaben"
      expect(find("#event_application_questions_attributes_0_question+p").text)
        .to eq "Aaa question?"
      expect(find("#event_application_questions_attributes_1_question+p").text).to eq "AHV-Nummer?"
    end
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
      fill_in "Spezialpreis", with: "89.05"

      expect do
        click_button("Speichern", match: :first)
        expect(page).to have_content(/Anlass .* wurde erfolgreich aktualisiert./)
        event.reload
      end
        .to change { event.price_member }.to(100.05)
        .and change { event.price_regular }.to(100.15)
        .and change { event.price_subsidized }.to(90.05)
        .and change { event.price_special }.to(89.05)

      price_selector = "#main article"
      find(price_selector).assert_text("Mitgliederpreis CHF 100.05")
      find(price_selector).assert_text("Normalpreis CHF 100.15")
      find(price_selector).assert_text("Subventionierter Preis CHF 90.05")
      find(price_selector).assert_text("Spezialpreis CHF 89.05")
    end

    it "displays j_s price labels in form when course is a j_s course" do
      event.kind.kind_category.update_column(:j_s_course, true)
      visit edit_group_event_path(group_id: group.id, id: event.id)
      click_tab "Preise"

      expect(page).to have_content "J&S P-Mitgliederpreis"
      expect(page).to have_content "J&S P-Normalpreis"
      expect(page).to have_content "J&S A-Mitgliederpreis"
      expect(page).to have_content "J&S A-Normalpreis"
    end

    it "displays j_s price labels in show when course is a j_s course" do
      event.kind.kind_category.update_column(:j_s_course, true)
      event.update_columns(price_member: 10, price_regular: 20, price_subsidized: 5,
        price_special: 3)
      visit group_event_path(group_id: group.id, id: event.id)

      expect(page).to have_content "J&S P-Mitgliederpreis"
      expect(page).to have_content "J&S P-Normalpreis"
      expect(page).to have_content "J&S A-Mitgliederpreis"
      expect(page).to have_content "J&S A-Normalpreis"
    end
  end

  context "attendents" do
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
      # rubocop:todo Layout/LineLength
      expect(page).to have_content("Teilnahme von Anna Admin in Tourenleiter/in 1 Sommer wurde erfolgreich aktualisiert.")
      # rubocop:enable Layout/LineLength
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

  context "tour" do
    let(:event) { events(:section_tour) }

    context "edit essentials" do
      it "shows options in tom select and sets them correctly" do
        # assigned but soft deleted entries should still be available in dropdown
        event.disciplines.first.update!(deleted_at: 1.month.ago)
        event_disciplines(:bergtour).update!(short_description: "Über Stock und Stein")
        visit edit_group_event_path(group_id: event.group_ids.first, id: event.id)

        within("#event_discipline_ids + .ts-wrapper") do
          expect(page).to have_selector(".ts-control .item", count: 1)
          expect(page).to have_selector(".ts-control .item", text: "Wanderweg")

          find(".ts-control input").click
          expect(page).to have_selector(".ts-dropdown .optgroup:first-child .optgroup-header", text: "Wandern")
          expect(page).to have_selector(".ts-dropdown .option:nth-child(2)", text: "Bergtour")
          expect(page).to have_selector(".ts-dropdown .option:nth-child(2) .muted", text: "Über Stock und Stein")
          expect(page).to have_selector(".ts-dropdown .option:nth-child(3)", text: "Schneeschuhwandern")
          expect(page).to have_no_selector(".ts-dropdown .option:nth-child(3) .muted")
          expect(page).to have_selector(".ts-dropdown .optgroup", count: Event::Discipline.main.count)
          expect(page).to have_selector(".ts-dropdown .option",
            count: Event::Discipline.where.not(parent: nil).count - 1) # 1 already selected

          find(".ts-dropdown .option", text: "Fels").click
          expect(page).to have_selector(".ts-control .item", text: "Fels")

          # close dropdown again
          find(".ts-control input").click
          expect(page).to have_no_selector(".ts-dropdown")
        end

        within("#event_target_group_ids + .ts-wrapper") do
          expect(page).to have_selector(".ts-control .item", count: 2)
          expect(page).to have_selector(".ts-control .item", text: "Kinder (KiBe)")
          expect(page).to have_selector(".ts-control .item", text: "Familien (FaBe)")
          find(".ts-control .item:nth-child(2) .remove").click
          expect(page).to have_selector(".ts-control .item", count: 1)

          find(".ts-control input").click
          expect(page).to have_selector(".ts-dropdown .option",
            count: Event::TargetGroup.count - 1) # 1 already selected

          find(".ts-dropdown .option", text: "Senioren B").click
          expect(page).to have_selector(".ts-control .item", text: "Senioren B")

          # close dropdown again
          find(".ts-control input").click
          expect(page).to have_no_selector(".ts-dropdown")
        end

        within("#event_fitness_requirement_id + .ts-wrapper") do
          expect(page).to have_selector(".ts-control .item", count: 1)
          expect(page).to have_selector(".ts-control .item", text: "B - wenig anstrengend")

          find(".ts-control").click
          expect(page).to have_selector(".ts-dropdown .option",
            count: Event::FitnessRequirement.count)

          find(".ts-dropdown .option", text: "A - nicht anstrengend").click
          expect(page).to have_selector(".ts-control .item", text: "A - nicht anstrengend")
          expect(page).to have_no_selector(".ts-dropdown")
        end

        within("#event_technical_requirement_ids + .ts-wrapper") do
          expect(page).to have_selector(".ts-control .item", count: 2)
          expect(page).to have_selector(".ts-control .item", text: "T3")
          expect(page).to have_selector(".ts-control .item", text: "T4")

          find(".ts-control input").click
          expect(page).to have_selector(".ts-dropdown .optgroup", count: Event::TechnicalRequirement.main.count)
          expect(page).to have_selector(".ts-dropdown .option",
            count: Event::TechnicalRequirement.where.not(parent: nil).count - 2) # 2 already selected

          find(".ts-dropdown .option", text: "WS").click
          expect(page).to have_selector(".ts-control .item", text: "WS")

          # close dropdown again
          find(".ts-control input").click
          expect(page).to have_no_selector(".ts-dropdown")
        end

        within("#event_trait_ids + .ts-wrapper") do
          expect(page).to have_selector(".ts-control .item", count: 2)
          expect(page).to have_selector(".ts-control .item", text: "Anreise mit ÖV")
          expect(page).to have_selector(".ts-control .item", text: "Exkursion")

          find(".ts-control input").click
          expect(page).to have_selector(".ts-dropdown .optgroup", count: Event::Trait.main.count - 1) # 1 selected
          expect(page).to have_selector(".ts-dropdown .option",
            count: Event::Trait.where.not(parent: nil).count - 2) # 2 already selected

          find(".ts-dropdown .option", text: "Arbeitseinsatz").click
          expect(page).to have_selector(".ts-control .item", text: "Arbeitseinsatz")

          # close dropdown again
          find(".ts-control input").click
          expect(page).to have_no_selector(".ts-dropdown")
        end

        click_tab "Daten"
        expect(page).to have_select "Saison", selected: "(keine)"
        select "Winter"
        expect(page).to have_select "Saison", selected: "Winter"

        click_on "Speichern", match: :first

        expect(page).to have_selector("section h2", text: "Anmeldung")

        expect(page).to have_selector("section h2", text: "Wesentliche Fakten")
        expect(page).to have_content("Wandern (Wanderweg)")
        expect(page).to have_content("Klettern (Fels)")

        expect(page).to have_content("Kinder (KiBe)")
        expect(page).to have_content("Senioren (Senioren B)")

        expect(page).to have_content("A - nicht anstrengend")

        expect(page).to have_content("Wanderskala: T3, T4")
        expect(page).to have_content("Skitourenskala: WS")

        expect(page).to have_content("Anreise mit ÖV, Arbeitseinsatz, Exkursion")

        event.reload
        expect(event.disciplines).to match_array(event_disciplines(:wanderweg, :felsklettern))
        expect(event.target_groups).to match_array(event_target_groups(:kinder, :senioren_b))
        expect(event.technical_requirements)
          .to match_array(event_technical_requirements(:wandern_t3, :wandern_t4, :skitouren_ws))
        expect(event.fitness_requirement).to eq(event_fitness_requirements(:a))
        expect(event.traits).to match_array(event_traits(:public_transport, :excursion, :work))
      end
    end
  end
end
