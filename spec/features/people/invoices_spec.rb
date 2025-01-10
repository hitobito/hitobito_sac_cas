# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "people invoices page" do
  let(:admin) { people(:admin) }

  before do
    travel_to(Time.zone.local(2024, 4, 1)) { sign_in(admin) }
  end

  context "no issues" do
    it "doesn't show an alert" do
      visit new_group_person_membership_invoice_path(group_id: admin.groups.first.id, person_id: admin.id)
      expect(page).not_to have_css(".alert-danger")
    end
  end

  context "data quality issues" do
    before { admin.update!(first_name: nil) }

    it "shows an alert message" do
      visit new_group_person_membership_invoice_path(group_id: admin.groups.first.id, person_id: admin.id)
      expect(page).to have_css(".alert-danger", text: "Vorname ist leer")
    end
  end

  context "on non main_family_person family member" do
    let(:person) { people(:familienmitglied2) }

    it "shows an alert message" do
      visit new_group_person_membership_invoice_path(group_id: person.groups.first.id, person_id: person.id)
      expect(page).to have_css(".alert-warning", text: "Diese Person verfügt über keine eigene Mitgliedschaftsrechnung. " \
                               "Die Gebühren werden allenfalls mit der Rechnung einer anderen Person verrechnet.")
    end
  end

  context "double submit" do
    let(:person) { people(:mitglied) }

    it "submits invoice on second submit when first reference date was not in active membership range" do
      person.sac_membership.stammsektion_role.update_columns(terminated: true, end_on: Time.zone.local(2024, 12, 31))

      visit new_group_person_membership_invoice_path(group_id: person.groups.first.id, person_id: person.id)
      fill_in "Stichtag", with: "01.01.2025"
      click_button "Rechnung erstellen"
      expect(page).to have_text "Mitgliedschaft ist nicht gültig"
      fill_in "Stichtag", with: "06.06.2024"
      click_button "Rechnung erstellen"
      expect(page).to have_text "Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt"
    end
  end
end
