# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "people invoices page", js: true do
  let(:admin) { people(:admin) }

  before do
    sign_in(admin)
  end

  describe "membership invoices" do
    context "no issues" do
      it "doesn't show an alert" do
        visit new_group_person_membership_invoice_path(group_id: admin.groups.first.id,
          person_id: admin.id)
        expect(page).not_to have_css(".alert-danger")
      end
    end

    context "data quality issues" do
      before { admin.update!(first_name: nil) }

      it "shows an alert message" do
        visit new_group_person_membership_invoice_path(group_id: admin.groups.first.id,
          person_id: admin.id)
        expect(page).to have_css(".alert-danger", text: "Vorname ist leer")
      end
    end

    context "on non main_family_person family member" do
      let(:person) { people(:familienmitglied2) }

      it "shows an alert message" do
        visit new_group_person_membership_invoice_path(group_id: person.groups.first.id,
          person_id: person.id)
        # rubocop:todo Layout/LineLength
        # rubocop:todo Layout/LineLength
        expect(page).to have_css(".alert-warning", text: "Diese Person verfügt über keine eigene Mitgliedschaftsrechnung. " \
                                "Die Gebühren werden allenfalls mit der Rechnung einer anderen Person verrechnet.")
        # rubocop:enable Layout/LineLength
        # rubocop:enable Layout/LineLength
      end
    end

    context "double submit" do
      let(:person) { people(:mitglied) }

      # rubocop:todo Layout/LineLength
      it "submits invoice on second submit when first reference date was not in active membership range" do
        # rubocop:enable Layout/LineLength
        person.sac_membership.stammsektion_role.update_columns(terminated: true,
          end_on: Time.zone.local(2024, 12, 31))

        travel_to(Time.zone.local(2024, 4, 1)) do
          visit new_group_person_membership_invoice_path(group_id: person.groups.first.id,
            person_id: person.id)
          fill_in "Stichtag", with: "01.01.2025"
          click_button "Rechnung erstellen"
          expect(page).to have_text "Mitgliedschaft ist nicht gültig"
          fill_in "Stichtag", with: "06.06.2024"
          click_button "Rechnung erstellen"
          expect(page).to have_text "Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt"
        end
      end
    end
  end

  describe "abo magazin invoices" do
    let(:person) { people(:abonnent) }
    let(:group) { groups(:abo_die_alpen) }

    context "no issues" do
      it "doesn't show an alert" do
        visit new_group_person_abo_magazin_invoice_path(group_id: group, person_id: person.id)
        expect(page).not_to have_css(".alert-danger")
      end

      it "creates invoice for selected abo group" do
        # create second abo role for french magazine
        abo_group_fr = Fabricate(Group::AboMagazin.sti_name, parent: groups(:abo_magazine),
          name: "Les Alpes FR")
        Fabricate(Group::AboMagazin::Abonnent.sti_name, group: abo_group_fr, person: person,
          end_on: person.roles.first.end_on)

        visit new_group_person_abo_magazin_invoice_path(group_id: group, person_id: person.id)
        expect(page).to have_text "Die Alpen Rechnung erstellen"
        choose "Les Alpes FR", allow_label_click: true
        click_button "Rechnung erstellen"
        # rubocop:todo Layout/LineLength
        expect(page).to have_text "Rechnung Les Alpes FR #{abo_group_fr.roles.first.end_on.next_day.year}"
        # rubocop:enable Layout/LineLength
        expect(ExternalInvoice.last.link).to eq abo_group_fr
      end

      # rubocop:todo Layout/LineLength
      it "updates issued_at from end_on + 1.day of abonnent role to start_on of neuanmeldungs role when selecting neuanmeldung" do
        # rubocop:enable Layout/LineLength
        # create second abo role for french magazine
        abo_group_fr = Fabricate(Group::AboMagazin.sti_name, parent: groups(:abo_magazine),
          name: "Les Alpes FR")
        neuanmeldung_role = Fabricate(Group::AboMagazin::Neuanmeldung.sti_name,
          group: abo_group_fr, person: person, start_on: Date.current)

        visit new_group_person_abo_magazin_invoice_path(group_id: group, person_id: person.id)
        expect(page).to have_text "Die Alpen Rechnung erstellen"
        expect(page).to have_field("Rechnungsdatum",
          with: I18n.l(roles(:abonnent_alpen).end_on.next_day), disabled: true)
        choose "Les Alpes FR", allow_label_click: true
        expect(page).to have_field("Rechnungsdatum", with: I18n.l(neuanmeldung_role.start_on),
          disabled: true)
        expect(page).not_to have_field("Rechnungsdatum",
          with: I18n.l(roles(:abonnent_alpen).end_on.next_day), disabled: true)
      end
    end

    context "data quality issues" do
      before do
        person.update_column(:first_name, nil)
        People::DataQualityChecker.new(person).check_data_quality
      end

      it "shows an alert message" do
        visit new_group_person_abo_magazin_invoice_path(group_id: group, person_id: person.id)
        expect(page).to have_css(".alert-danger", text: "Vorname ist leer")
      end
    end

    context "no abo role" do
      let(:person) { people(:mitglied) }

      it "shows an alert message" do
        visit new_group_person_abo_magazin_invoice_path(group_id: group, person_id: person.id)
        expect(page).to have_css(".alert-warning",
          # rubocop:todo Layout/LineLength
          text: "Diese Person ist kein/e Abonnent/in eines Magazin, daher kann keine Abo Rechnung erstellt werden.")
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
