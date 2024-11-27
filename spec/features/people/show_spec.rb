# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "person show page" do
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:geschaeftsstelle) { groups(:geschaeftsstelle) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }
  let(:other) do
    Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023)
      .children.find_by(type: Group::SektionsMitglieder)
  end

  before { sign_in(admin) }

  describe "roles" do
    describe "her own" do
      it "shows link to change main group" do
        visit group_person_path(group_id: geschaeftsstelle.id, id: admin.id)
        expect(page).to have_link "Hauptgruppe setzen"
      end

      it "shows link to change main group if person is Mitglied in a Sektion" do
        travel_to Date.new(2023, 8, 1)
        Fabricate(
          Group::SektionsMitglieder::Mitglied.sti_name,
          group: mitglieder,
          person: admin,
          beitragskategorie: :adult,
          start_on: Date.new(2023, 2, 1),
          end_on: Date.new(2023, 12, 31)
        )
        visit group_person_path(group_id: geschaeftsstelle.id, id: admin.id)
        expect(page).to have_link "Hauptgruppe setzen"
        expect(page).to have_css("section.roles", text: "SAC Blüemlisalp / Mitglieder\nMitglied (Stammsektion) (Einzel) (bis 31.12.2023)")
      end
    end

    describe "others" do
      it "shows Hauptgruppe setzen link to" do
        visit group_person_path(group_id: geschaeftsstelle.id, id: admin.id)
        expect(page).to have_link "Hauptgruppe setzen"
      end
    end

    describe "wizard managed roles" do
      let(:role) { roles(:mitglied) }

      it "doesn't show delete button" do
        visit group_person_path(group_id: role.group_id, id: role.person_id)
        expect(page).not_to have_css("a[title=\"Löschen\"]")
      end

      describe "other roles" do
        let(:role) { roles(:tourenchef_bluemlisalp_ortsgruppe_ausserberg) }

        it "shows delete button" do
          visit group_person_path(group_id: role.group_id, id: role.person_id)
          expect(page).to have_css("a[title=\"Löschen\"]")
        end
      end
    end
  end

  describe "data quality" do
    context "with data quality issues" do
      before do
        admin.update!(data_quality: "error")
        admin.data_quality_issues.create!(attr: "email", key: "empty", severity: "warning")
        admin.data_quality_issues.create!(attr: "street", key: "empty", severity: "error")
      end

      it "shows the data quality issues" do
        visit group_person_path(group_id: geschaeftsstelle.id, id: admin.id)
        expect(page).to have_text("Datenqualität")
        expect(page).to have_css("i[title='Fehler']")
        expect(page).to have_text("Strasse ist leer")
        expect(page).to have_css("i[title='Warnung']")
        expect(page).to have_text("Haupt-E-Mail ist leer")
      end
    end

    context "without data quality issues" do
      it "doesn't show the data quality section" do
        visit group_person_path(group_id: geschaeftsstelle.id, id: admin.id)
        expect(page).not_to have_text("Datenqualität")
      end
    end
  end

  describe "person without roles" do
    let(:person_without_role) { Fabricate(:person) }

    it "shows full person view and can view history" do
      visit group_person_path(group_id: groups(:root).id, id: person_without_role.id)
      expect(page).to have_link "Mitgliedschaften / Verlauf"
      expect(page).to have_css "h2", text: "Weitere Angaben"
      click_on "Mitgliedschaften / Verlauf"
      expect(page).to have_text "Hier kannst du deine Mitgliedschaften verwalten"
    end
  end
end
