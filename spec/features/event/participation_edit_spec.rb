# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "participation edit page", :js do
  let(:person) { people(:admin) }
  let(:event) { Fabricate(:sac_open_course, state: nil) }
  let(:participation) { Fabricate(:event_participation, event:, person:, application_id: -1) }
  let(:participation_path) { edit_group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id) }

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
      expect do
        click_on("Speichern")
        expect(page).to have_css(".alert", text: "Teilnahme von Anna Admin in Eventus wurde erfolgreich aktualisiert.")
      end.to change { participation.reload.price }.from(10).to(nil)
    end

    it "shows options for present prices" do
      visit participation_path
      within "#event_participation_price_category" do
        expect(page).not_to have_css("option", text: "Keine Kosten")
        expect(page).to have_css("option[selected]", text: "Mitgliederpreis CHF 10.00")
        expect(page).to have_css("option", text: "Normalpreis CHF 20.00")
        select "Normalpreis CHF 20.00"
      end
      expect do
        click_on("Speichern")
        expect(page).to have_css(".alert", text: "Teilnahme von Anna Admin in Eventus wurde erfolgreich aktualisiert.")
      end.to change { participation.reload.price }.from(10).to(20)
    end

    it "shows option with former price if event price changed" do
      event.update!(price_member: 15)

      visit participation_path
      within "#event_participation_price_category" do
        expect(page).to have_css("option[selected]", text: "Bisheriger Mitgliederpreis CHF 10.00")
        expect(page).to have_css("option", text: "Mitgliederpreis CHF 15.00")
        expect(page).to have_css("option", text: "Normalpreis CHF 20.00")
      end
      expect do
        click_on("Speichern")
        expect(page).to have_css(".alert", text: "Teilnahme von Anna Admin in Eventus wurde erfolgreich aktualisiert.")
      end.not_to change { participation.reload.price }
    end

    it "can select new price" do
      event.update!(price_member: 15)

      visit participation_path
      within "#event_participation_price_category" do
        expect(page).to have_css("option[selected]", text: "Bisheriger Mitgliederpreis CHF 10.00")
        select "Mitgliederpreis CHF 15.00"
      end
      expect do
        click_on("Speichern")
        expect(page).to have_css(".alert", text: "Teilnahme von Anna Admin in Eventus wurde erfolgreich aktualisiert.")
      end.to change { participation.reload.price }.from(10).to(15)
    end

    it "shows j_s price labels for j_s courses" do
      event.kind.kind_category.update_column(:j_s_course, true)
      visit participation_path
      within "#event_participation_price_category" do
        expect(page).to have_css("option", text: "J&S P-Mitgliederpreis CHF 10.00")
        expect(page).to have_css("option", text: "J&S P-Normalpreis CHF 20.00")
      end
    end
  end
end
