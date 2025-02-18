# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "group edit page" do
  let(:admin) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }

  before { sign_in(admin) }

  describe "phone numbers", js: true do
    it "can set phone numbers" do
      expect do
        visit edit_group_path(id: group.id)
        click_link "Kontaktangaben"
        fill_in "Festnetz", with: "0441234567"
        fill_in "Mobil", with: "0791234567"
        click_button "Speichern"
        expect(page).to have_text(/Gruppe.*wurde erfolgreich aktualisiert./)
      end.to change { PhoneNumber.count }.by(2)
        .and change { group.reload.phone_number_landline&.number }
        .from(nil).to("+41 44 123 45 67")
        .and change { group.reload.phone_number_mobile&.number }
        .from(nil).to("+41 79 123 45 67")
    end

    it "can update phone numbers" do
      group.create_phone_number_landline!(number: "0441234567")
      expect do
        visit edit_group_path(id: group.id)
        click_link "Kontaktangaben"
        expect(page).to have_field("Festnetz",
          with: "+41 44 123 45 67")
        fill_in "Festnetz", with: "+41 44 765 43 21"
        click_button "Speichern", match: :first
        expect(page).to have_text(/Gruppe.*wurde erfolgreich aktualisiert./)
      end.to change { PhoneNumber.count }.by(0)
        .and change { group.reload.phone_number_landline&.number }
        .from("+41 44 123 45 67").to("+41 44 765 43 21")
    end

    it "can remove phone numbers" do
      group.create_phone_number_landline!(number: "0441234567")
      group.create_phone_number_mobile!(number: "0791234567")
      expect do
        visit edit_group_path(id: group.id)
        click_link "Kontaktangaben"
        expect(page).to have_field("Festnetz",
          with: "+41 44 123 45 67")
        expect(page).to have_field("Mobil",
          with: "+41 79 123 45 67")
        fill_in "Festnetz", with: ""
        fill_in "Mobil", with: ""
        click_button "Speichern", match: :first
        expect(page).to have_text(/Gruppe.*wurde erfolgreich aktualisiert./)
      end.to change { PhoneNumber.count }.by(-2)
        .and change { group.reload.phone_number_landline&.number }
        .from("+41 44 123 45 67").to(nil)
        .and change { group.reload.phone_number_mobile&.number }
        .from("+41 79 123 45 67").to(nil)
    end
  end
end
