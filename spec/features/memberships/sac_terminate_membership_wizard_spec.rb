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
  let(:additional_section) { groups(:matterhorn) }

  before do
    sign_in(operator)
  end

  context "as SAC Mitarbeiter" do
    let(:operator) { people(:admin) }

    it "can execute wizard with immediate deletion" do
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
        .to change { person.roles.count }.by(-2)
        .and change { role.deleted_at }.from(nil)
        .and change { role.termination_reason }.from(nil).to(termination_reason)
    end

    it "can execute wizard at end of year" do
      role.update!(delete_on: Date.new(Date.current.year + 1, 12, 31))
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
        .and change { role.delete_on }.to(Date.new(Date.current.year, 12, 31))
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
        additional_section.update!(mitglied_termination_by_section_only: false)
        role.layer_group.update!(mitglied_termination_by_section_only: true)
      end

      after do
        additional_section.update!(mitglied_termination_by_section_only: false)
        role.layer_group.update!(mitglied_termination_by_section_only: false)
      end

      it "shows an info text" do
        visit history_group_person_path(group_id: group.id, id: person.id)
        within("#role_#{role.id}") do |content|
          expect(content).to have_selector("[title='Für einen Austritt musst du dich an den Mitgliederdienst der Sektion wenden']")
        end
      end
    end

    context "when zusatzsektion has mitglied_termination_by_section_only=true" do
      before do
        role.layer_group.update!(mitglied_termination_by_section_only: false)
        additional_section.update!(mitglied_termination_by_section_only: true)
      end

      after do
        additional_section.update!(mitglied_termination_by_section_only: false)
        role.layer_group.update!(mitglied_termination_by_section_only: false)
      end

      it "shows an info text" do
        visit history_group_person_path(group_id: group.id, id: person.id)
        within("#role_#{role.id}") do |content|
          expect(content).to have_selector("[title='Für einen Austritt musst du dich an den Mitgliederdienst der Sektion wenden']")
        end
      end
    end
  end

  context "as family main person" do
    let(:person) { people(:familienmitglied) }
    let(:additional_section) { groups(:matterhorn) }
    let(:familymember) { people(:familienmitglied2) }

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

    context "when additional section of familymember has mitglied_termination_by_section_only=true" do
      let(:terminate_on) { Time.zone.now.yesterday.to_date }
      let(:termination_reason) { termination_reasons(:moved) }

      before do
        # check that additional section
        role.layer_group.update!(mitglied_termination_by_section_only: false)
        additional_section.update!(mitglied_termination_by_section_only: true)
        # leave additional section for the main person to check state for family member
        additional_section.update_columns(deleted_at: Time.zone.now.yesterday)
      end

      after do
        # restore the main person addtional section role to not affect other tests
        additional_section.update_columns(deleted_at: nil)
        role.layer_group.update!(mitglied_termination_by_section_only: false)
        additional_section.update!(mitglied_termination_by_section_only: false)
      end

      it "shows an info text" do
        visit history_group_person_path(group_id: group.id, id: person.id)
        within("#role_#{role.id}") do |content|
          expect(content).to have_selector("[title='Für einen Austritt musst du dich an den Mitgliederdienst der Sektion wenden']")
        end
      end
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
