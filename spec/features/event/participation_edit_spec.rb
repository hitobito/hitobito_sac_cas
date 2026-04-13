# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "participation edit page", :js do
  let(:person) { people(:admin) }
  let(:event) { Fabricate(:sac_open_course, state: nil) }
  let(:participation) {
    Fabricate(:event_participation, event:, participant: people(:mitglied), application_id: -1)
  }
  let(:participation_path) {
    edit_group_event_participation_path(group_id: event.group_ids.first, event_id: event.id,
      id: participation.id)
  }

  before { sign_in(person) }

  context "event without prices" do
    before { event.update!(price_member: nil, price_regular: nil) }

    it "shows empty price option" do
      visit participation_path
      within "#event_participation_price_category" do
        expect(page).to have_css("option[selected]", text: "Keine Kosten")
      end
    end
  end

  context "event with prices" do
    before { participation.update!(price: 10, price_category: "price_member") }

    it "shows empty price option for leaders" do
      participation.roles.create!(type: Event::Course::Role::AssistantLeader)

      visit participation_path
      within "#event_participation_price_category" do
        expect(page).to have_css("option", text: "Keine Kosten")
        select "Keine Kosten"
      end

      expect(page).to have_field("event_participation_price", with: "0.00")

      expect do
        click_on("Speichern")
        expect(page).to have_css(".alert",
          text: "Teilnahme von Edmund Hillary in Eventus wurde erfolgreich aktualisiert.")
      end.to change { participation.reload.price }.from(10).to(0.0)
    end

    it "shows options for present prices" do
      visit participation_path
      within "#event_participation_price_category" do
        expect(page).not_to have_css("option", text: "Keine Kosten")
        expect(page).to have_css("option[selected]", text: "Mitgliederpreis CHF 10.00")
        expect(page).to have_css("option", text: "Normalpreis CHF 20.00")
        select "Normalpreis CHF 20.00"
      end

      expect(page).to have_field("event_participation_price", with: "20.00")

      expect do
        click_on("Speichern")
        expect(page).to have_css(".alert",
          text: "Teilnahme von Edmund Hillary in Eventus wurde erfolgreich aktualisiert.")
      end.to change { participation.reload.price }.from(10).to(20)
    end

    it "can set custom price" do
      visit participation_path
      within "#event_participation_price_category" do
        expect(page).to have_css("option", text: "Normalpreis CHF 20.00")
        select "Normalpreis CHF 20.00"
      end

      expect(page).to have_field("event_participation_price", with: "20.00")

      fill_in "Preis", with: "400"

      expect do
        click_on("Speichern")
        expect(page).to have_css(".alert",
          text: "Teilnahme von Edmund Hillary in Eventus wurde erfolgreich aktualisiert.")
      end.to change { participation.reload.price }.from(10).to(400)
    end

    it "shows j_s price labels for j_s courses" do
      event.kind.kind_category.update_column(:j_s_course, true)
      visit participation_path
      within "#event_participation_price_category" do
        expect(page).to have_css("option", text: "J&S P-Mitgliederpreis CHF 10.00")
        expect(page).to have_css("option", text: "J&S P-Normalpreis CHF 20.00")
      end
    end

    it "does not show price_category and price field for own participation" do
      participation.update!(participant: person)

      visit participation_path
      expect(page).to have_no_text "Preiskategorie"
      expect(page).to have_no_text "Preis"
    end
  end

  context "edit her own participation" do
    let(:person) { people(:mitglied) }

    it "does not show price field" do
      visit participation_path
      expect(page).to have_no_text "Preis"
    end
  end
end
