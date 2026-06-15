# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "person edit page", js: true do
  let(:admin) { people(:admin) }
  let(:member) { people(:mitglied) }
  let(:edit_path) { edit_group_person_path(group_id: member.group_ids.first, id: member.id) }

  before { sign_in(admin) }

  describe "required fields" do
    it "shows error that fields should be filled out" do
      visit edit_path
      fill_in "Nachname", with: ""
      fill_in "person[street]", with: ""
      click_button "Speichern", match: :first
      expect(page).to have_text("Nachname muss ausgefüllt werden")
      expect(page).to have_text("Strasse muss ausgefüllt werden")
    end
  end

  describe "phone numbers" do
    it "can set phone numbers" do
      expect do
        visit edit_path
        fill_in "Festnetz", with: "0441234567"
        fill_in "Mobil", with: "0791234567"
        click_button "Speichern", match: :first
        expect(page).to have_text(/Person.*wurde erfolgreich aktualisiert./)
      end.to change { PhoneNumber.count }.by(2)
        .and change { member.reload.phone_number_landline&.number }.from(nil).to("+41 44 123 45 67")
        .and change { member.reload.phone_number_mobile&.number }.from(nil).to("+41 79 123 45 67")
    end

    it "can update phone numbers" do
      member.create_phone_number_landline!(number: "0441234567")
      expect do
        visit edit_path
        expect(page).to have_field("Festnetz",
          with: "+41 44 123 45 67")
        fill_in "Festnetz", with: "0447654321"
        click_button "Speichern", match: :first
        expect(page).to have_text(/Person.*wurde erfolgreich aktualisiert./)
      end.to change { PhoneNumber.count }.by(0)
        .and change { member.reload.phone_number_landline&.number }
        .from("+41 44 123 45 67").to("+41 44 765 43 21")
    end

    it "can remove phone numbers" do
      member.create_phone_number_landline!(number: "0441234567")
      member.create_phone_number_mobile!(number: "0791234567")
      expect do
        visit edit_path
        expect(page).to have_field("Festnetz",
          with: "+41 44 123 45 67")
        expect(page).to have_field("Mobil",
          with: "+41 79 123 45 67")
        fill_in "Festnetz", with: ""
        fill_in "Mobil", with: ""
        click_button "Speichern", match: :first
        expect(page).to have_text(/Person.*wurde erfolgreich aktualisiert./)
      end.to change { PhoneNumber.count }.by(-2)
        .and change { member.reload.phone_number_landline&.number }
        .from("+41 44 123 45 67").to(nil)
        .and change { member.reload.phone_number_mobile&.number }
        .from("+41 79 123 45 67").to(nil)
    end
  end

  describe "canton" do
    def select_country(name)
      find("#person_country + .ts-wrapper .ts-control").click
      find(".ts-dropdown-content .option", text: name).click
    end

    it "is visible on page load when country is switzerland" do
      visit edit_path

      expect(page).to have_css("[data-field-visibility-target='container']")
    end

    it "is hidden on page load when country is not switzerland" do
      member.update!(country: "DE", zip_code: 12345)

      visit edit_path

      expect(page).to have_css("[data-field-visibility-target='container']", visible: false)
    end

    it "hides when country changes to non-swiss country and clears input values" do
      member.update!(canton: "be")
      visit edit_path

      expect(find("#person_canton").value).to eq("be")
      expect(page).to have_css("[data-field-visibility-target='container']")

      select_country("Deutschland")

      expect(page).to have_css("[data-field-visibility-target='container']", visible: false)
      expect(find("#person_canton", visible: false).value).to eq("")
    end

    it "turns visible when country changes to switzerland" do
      member.update!(country: "DE", zip_code: 12345)
      visit edit_path

      expect(page).to have_css("[data-field-visibility-target='container']", visible: false)

      select_country("Schweiz")

      expect(page).to have_css("[data-field-visibility-target='container']")
    end
  end
end
