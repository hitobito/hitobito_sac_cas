# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "terminate sac membership wizard", js: true do
  let(:person) { people(:mitglied) }
  let(:role) { person.roles.first }
  let(:operator) { person }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:termination_reason) { termination_reasons(:deceased) }

  before do
    sign_in(operator)
  end

  context "as SAC Mitarbeiter" do
    let(:operator) { people(:admin) }

    xit "can execute wizard with immediate deletion" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      choose "Sofort"
      click_button "Weiter"
      select termination_reason.text
      check "Newsletter beibehalten"
      check "Meine Daten sollen nach dem Austritt erhalten blieben und ich kann für Spendenaufrufe kontaktiert werden"
      check "Ich möchte weiterhin über Spendenaktionen informiert werden."
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_content "Deine SAC-Mitgliedschaft wurde gekündet."
        role.reload
      end
        .to change { person.roles.count }.by(-1)
        .and change { role.deleted_at }.from(nil)
        .and change { role.termination_reason }.from(nil).to(termination_reason)
    end

    it "can execute wizard at end of year" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "SAC-Mitgliedschaft beenden"
      choose "Auf 31.12.#{Date.current.year}"
      click_button "Weiter"
      select termination_reason.text
      check "Newsletter beibehalten"
      check "Meine Daten sollen nach dem Austritt erhalten blieben und ich kann für Spendenaufrufe kontaktiert werden"
      check "Ich möchte weiterhin über Spendenaktionen informiert werden."
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_content "Deine SAC-Mitgliedschaft wurde gekündet."
        role.reload
      end
        .to change { role.termination_reason }.from(nil).to(termination_reason)
      # TODO: role delete_on should change to end of year?
      # .and change { role.delete_on }.to(Date.new(Date.current.year, 12, 31))
    end
  end

  context "as normal user" do
    it "can execute wizard and leave by end of year" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "SAC-Mitgliedschaft beenden"
      select termination_reason.text
      check "Newsletter beibehalten"
      check "Meine Daten sollen nach dem Austritt erhalten blieben und ich kann für Spendenaufrufe kontaktiert werden"
      check "Ich möchte weiterhin über Spendenaktionen informiert werden."
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_content "Deine SAC-Mitgliedschaft wurde gekündet."
        role.reload
      end
        .to not_change { person.roles.count }
        .and change { role.terminated }.to(true)
        .and change { role.termination_reason }.from(nil).to(termination_reason)
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
      expect(page).to have_title "SAC-Mitgliedschaft beenden"
      select termination_reason.text
      expect do
        expect(page).to have_content "Achtung: der Austritt wird für die gesamte Familienmitgliedschaft beantragt"
        click_button "Austritt beantragen"
        expect(page).to have_content "Eure 3 SAC-Mitgliedschaften wurden gekündet."
        role.reload
      end
        .to not_change { person.roles.count }
        .and change { role.terminated }.to(true)
        .and change { role.termination_reason }.from(nil).to(termination_reason)
    end
  end

  context "as family regular person" do
    let(:person) { people(:familienmitglied2) }

    it "shows info about the main family person" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "SAC-Mitgliedschaft beenden"
      expect(page).to have_content("Bitte wende dich an #{people(:familienmitglied)}")
    end
  end
end
