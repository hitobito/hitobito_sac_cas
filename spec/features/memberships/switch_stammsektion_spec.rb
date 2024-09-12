# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "switching stammsektion", js: true do
  before do
    sign_in(person)
    visit group_person_path(group_id: group.id, id: person.id)

    Group::SektionsNeuanmeldungenSektion.delete_all # To allow self service
  end

  context "as normal user" do
    let(:group) { groups(:bluemlisalp_mitglieder) }
    let(:person) { people(:mitglied) }

    before do
      roles(:mitglied_zweitsektion).destroy
    end

    it "can open wizard via dropdown" do
      visit group_person_path(group_id: group.id, id: person.id)
      click_link "Mitgliedschaft anpassen"
      click_link "Sektionswechsel beantragen"
    end

    it "fills out form and redirects" do
      click_link "Mitgliedschaft anpassen"
      click_link "Sektionswechsel beantragen"
      expect(page).to have_css "h1", text: "Stammsektion wechseln"
      expect(page).to have_css "li.active", text: "Sektion wählen"
      select "SAC Matterhorn"
      click_on "Weiter"
      expect(page).to have_css "li.active", text: "Bestätigung"
      expect(page).to have_content "Beiträge in der Sektion SAC Matterhorn"
      click_on "Kostenpflichtig bestellen"
      expect(page).to have_css "#flash .alert-success",
        text: "Dein Sektionswechsel zu SAC Matterhorn wurde vorgenommen."
    end
  end

  context "as family user" do
    let(:group) { groups(:bluemlisalp_mitglieder) }
    let(:person) { people(:familienmitglied) }

    before do
      roles(:familienmitglied_zweitsektion).destroy
      roles(:familienmitglied2_zweitsektion).destroy
      roles(:familienmitglied_kind_zweitsektion).destroy
      person.update_column(:data_quality, :ok)
    end

    it "can switch for all members" do
      click_link "Mitgliedschaft anpassen"
      click_link "Sektionswechsel beantragen"
      expect(page).to have_css "li.active", text: "Sektion wählen"
      expect(find(".alert-info").text).to include("Achtung: Der Stammsektionsektionswechsel wird für die gesamte " \
        "Familienmitgliedschaft beantragt. Davon betroffen sind: ", "Tenzing Norgay", "Frieda Norgay", "Nima Norgay")
      select "SAC Matterhorn"
      click_on "Weiter"
      expect(page).to have_css "li.active", text: "Bestätigung"
      expect(page).to have_content "Beiträge in der Sektion SAC Matterhorn"
      expect do
        click_on "Kostenpflichtig bestellen"
        expect(page).to have_css "#flash .alert-success", text: "Eure 3 Sektionswechsel zu SAC Matterhorn wurden vorgenommen."
      end.to change(Delayed::Job.where(queue: :mailers), :count).by(1)
    end
  end

  context "with data quality issues" do
    let(:group) { groups(:bluemlisalp_mitglieder) }
    let(:person) { people(:familienmitglied) }

    before { person.update!(first_name: nil) }

    it "shows an alert info message" do
      click_link "Mitgliedschaft anpassen"
      click_link "Sektionswechsel beantragen"
      expect(find(".alert-info").text).to include("kann wegen ungültigen Daten nicht durchgeführt werden")
      expect(page).to have_text("Vorname ist leer")
    end
  end
end
