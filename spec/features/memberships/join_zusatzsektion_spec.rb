# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "joining zusatzsektion", js: true do
  before do
    sign_in(person)
    visit group_person_path(group_id: group.id, id: person.id)
  end

  context "as user without membership" do
    let(:group) { groups(:abo_die_alpen) }
    let(:person) { people(:abonnent) }

    it "does not have dropdown on person#show page" do
      visit group_person_path(group_id: group.id, id: person.id)
      expect(page).not_to have_link "Mitglieschaft anpassen"
    end
  end

  context "as normal user" do
    let(:group) { groups(:bluemlisalp_mitglieder) }
    let(:person) { people(:mitglied) }

    before do
      roles(:mitglied_zweitsektion).destroy
      person.data_quality_issues.destroy_all
    end

    it "has dropdown on person show page" do
      expect(page).to have_link "Mitgliedschaft anpassen"
    end

    it "can open wizard via dropdown" do
      visit group_person_path(group_id: group.id, id: person.id)
      click_link "Mitgliedschaft anpassen"
      click_link "Zusatzsektion beantragen"
      expect(page).to have_title "Zusatzsektion beitreten"
    end

    it "fills out form and redirects" do
      fill_out_form
      expect(page).to have_content "Die Zusatzmitgliedschaft bei SAC Matterhorn wird als Einzelmitglied beantragt."
      click_on "Kostenpflichtig bestellen"
      expect(page).to have_css "#flash .alert-success",
        text: "Deine Zusatzmitgliedschaft in SAC Matterhorn wurde erstellt."
    end

    it "can handle membership admission through gs" do
      allow_any_instance_of(SacCas::GroupDecorator).to receive(:membership_admission_through_gs?).and_return(true)
      fill_out_form
      expect(page).to have_content "Hiermit wird eine Rechnung ausgelöst."
      click_on "Kostenpflichtig bestellen"
      expect(page).to have_css "#flash .alert-success",
        text: "Deine Zusatzmitgliedschaft in SAC Matterhorn wurde erstellt."
    end

    it "can handle membership admission through sektion" do
      allow_any_instance_of(SacCas::GroupDecorator).to receive(:membership_admission_through_gs?).and_return(false)
      fill_out_form
      expect(page).to have_content "Hiermit wird noch keine Rechnung ausgelöst, erst mit erteilter Freigabe."
      click_on "Kostenpflichtig bestellen"
      expect(page).to have_css "#flash .alert-success",
        text: "Deine Zusatzmitgliedschaft in SAC Matterhorn wurde erstellt."
    end

    it "can apply as youth member" do
      person.update_column(:birthday, 20.years.ago)
      fill_out_form "Jugendmitgliedschaft"
      expect(page).to have_content "Die Zusatzmitgliedschaft bei SAC Matterhorn wird als Jugendmitglied beantragt."
      click_on "Kostenpflichtig bestellen"
      expect(page).to have_css "#flash .alert-success",
        text: "Deine Zusatzmitgliedschaft in SAC Matterhorn wurde erstellt."
    end
  end

  context "as family user" do
    let(:group) { groups(:bluemlisalp_mitglieder) }

    before do
      roles(:familienmitglied_zweitsektion).destroy
      Group::SektionsNeuanmeldungenSektion.delete_all
      person.update_column(:data_quality, :ok)
      person.data_quality_issues.destroy_all
      click_link "Mitgliedschaft anpassen"
      click_link "Zusatzsektion beantragen"
      expect(page).to have_css "li.active", text: "Familienmitgliedschaft"
    end

    context "main person" do
      let(:person) { people(:familienmitglied) }

      it "can for single person" do
        choose "für mich selbst"
        click_on "Weiter"
        expect(page).to have_css "li.active", text: "Sektion wählen"
        select "SAC Matterhorn"
        click_on "Weiter"
        expect(page).to have_css "li.active", text: "Bestätigung"
        expect(page).to have_content "Einzelmitgliedschaft SAC Matterhorn"
        expect(page).not_to have_css(".card", text: "einmalige Eintrittsgebühr")
        expect do
          click_on "Kostenpflichtig bestellen"
          expect(page).to have_css "#flash .alert-success",
            text: "Deine Zusatzmitgliedschaft in SAC Matterhorn wurde erstellt."
        end.to change { Role.count }.by(1)
      end

      it "can create roles for all members" do
        # remove existing roles in group so we can test without conflicting roles
        groups(:matterhorn_mitglieder).roles.delete_all

        choose "für die ganze Familie"
        click_on "Weiter"
        expect(page).to have_css "li.active", text: "Sektion wählen"
        select "SAC Matterhorn"
        click_on "Weiter"
        expect(page).to have_css "li.active", text: "Bestätigung"
        expect(page).to have_content "Familienmitgliedschaft SAC Matterhorn"
        expect do
          click_on "Kostenpflichtig bestellen"
          expect(page).to have_css "#flash .alert-success",
            text: "Eure 3 Zusatzmitgliedschaften in SAC Matterhorn wurden erstellt."
        end.to change { Role.count }.by(3)
      end
    end
  end

  private

  def fill_out_form(beitragskategorie = "Einzelmitgliedschaft")
    click_link "Mitgliedschaft anpassen"
    click_link "Zusatzsektion beantragen"
    expect(page).to have_css "li.active", text: "Sektion wählen"
    select "SAC Matterhorn"
    click_on "Weiter"
    expect(page).to have_css "li.active", text: "Bestätigung"
    expect(page).to have_content "#{beitragskategorie} SAC Matterhorn"
  end
end
