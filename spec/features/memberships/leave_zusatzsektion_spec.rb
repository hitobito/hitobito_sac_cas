# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "leave zusatzsektion", js: true do
  let(:person) { people(:mitglied) }
  let(:role) { person.roles.second }
  let(:operator) { person }
  let(:group) { groups(:bluemlisalp_mitglieder) }

  before do
    sign_in(operator)
  end

  context "as SAC Mitarbeiter" do
    let(:operator) { people(:admin) }

    it "can execute wizard with immediate termination" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "Zusatzsektion verlassen"
      choose "Sofort"
      click_button "Weiter"
      select "einfach so"
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_content "Deine Zusatzmitgliedschaft in #{role.group.parent.name} wurde gelöscht."
      end
        .to change { person.roles.count }.by(-1)
        .and change { role.reload.deleted_at }.from(nil)
    end
  end

  context "as normal user" do
    it "can execute wizard and leave by end of year" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "Zusatzsektion verlassen"
      select "einfach so"
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_content "Deine Zusatzmitgliedschaft in #{role.group.parent.name} wurde gelöscht."
      end
        .to not_change { person.roles.count }
        .and change { role.reload.terminated }.to(true)
      expect(role.delete_on).not_to be_nil
    end

    context "when sektion has mitglied_termination_by_section_only=true" do
      before do
        role.layer_group.update!(mitglied_termination_by_section_only: true)
      end

      it "shows an info text" do
        visit group_person_role_leave_zusatzsektion_path(group_id: group.id, person_id: person.id, role_id: role.id)
        expect(page).to have_content("Wir bitten dich den Austritt telefonisch oder per E-Mail zu beantragen.")
      end
    end
  end

  context "as family main person" do
    let(:person) { people(:familienmitglied) }

    it "can execute wizard" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "Zusatzsektion verlassen"
      select "einfach so"
      expect do
        expect(page).to have_content "Der Austritt aus der Zusatzsektion wird für die gesamte Familienmitgliedschaft beantragt"
        click_button "Austritt beantragen"
        expect(page).to have_content "Eure 3 Zusatzmitgliedschaften in #{role.group.parent.name} wurden gelöscht."
      end
        .to not_change { person.roles.count }
        .and change { role.reload.terminated }.to(true)
    end
  end

  context "as family regular person" do
    let(:person) { people(:familienmitglied2) }

    it "shows info about the main family person" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "Zusatzsektion verlassen"
      expect(page).to have_content("Bitte wende dich an #{people(:familienmitglied)}")
    end
  end
end