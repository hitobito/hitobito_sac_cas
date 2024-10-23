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
      check "Meine Daten sollen nach dem Austritt erhalten bleiben und ich kann für Spendenaufrufe kontaktiert werden"
      check "Ich möchte weiterhin über Spendenaktionen informiert werden."
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_content "Deine SAC-Mitgliedschaft wurde gekündet."
        role.reload
      end
        .to change { person.roles.count }.by(-2)
        .and change { role.terminated }.to(true)
        .and change { role.end_on }.to(Date.current.yesterday)
        .and change { role.termination_reason }.from(nil).to(termination_reason)
    end

    it "can execute wizard at end of year" do
      role.update!(end_on: 10.years.from_now)
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "SAC-Mitgliedschaft beenden"
      choose "Auf 31.12.#{Date.current.year}"
      click_button "Weiter"
      select termination_reason.text
      check "Newsletter beibehalten"
      check "Meine Daten sollen nach dem Austritt erhalten bleiben und ich kann für Spendenaufrufe kontaktiert werden"
      check "Ich möchte weiterhin über Spendenaktionen informiert werden."
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_content "Deine SAC-Mitgliedschaft wurde gekündet."
        role.reload
      end
        .to change { role.termination_reason }.from(nil).to(termination_reason)
        .and change { role.terminated }.to(true)
        .and change { role.end_on }.to(Date.current.end_of_year)
    end

    describe "data retention checkboxes" do
      let(:data_retention_checkbox) { find(:checkbox, "Meine Daten sollen nach dem Austritt erhalten bleiben") }
      let(:newsletter_checkbox) { find(:checkbox, "Newsletter beibehalten") }
      let(:fundraising_checkbox) { find(:checkbox, "über Spendenaktionen informiert werden") }

      before do
        visit history_group_person_path(group_id: group.id, id: person.id)
        within("#role_#{role.id}") do
          click_link "Austritt"
        end
        choose "Sofort"
        click_button "Weiter"
      end

      it "checks data_retention_consent when subscribe_newsletter is checked" do
        check "Newsletter beibehalten"
        expect(data_retention_checkbox).to be_checked
        uncheck "Newsletter beibehalten"
        expect(newsletter_checkbox).not_to be_checked
        expect(data_retention_checkbox).to be_checked
      end

      it "checks data_retention_consent when sac spenden is checked" do
        check "Ich möchte weiterhin über Spendenaktionen informiert werden."
        expect(data_retention_checkbox).to be_checked
        uncheck "Ich möchte weiterhin über Spendenaktionen informiert werden."
        expect(fundraising_checkbox).not_to be_checked
        expect(data_retention_checkbox).to be_checked
      end

      it "unchecks all dependent checkboxes when unchecking master checkbox" do
        check "Newsletter beibehalten"
        check "Ich möchte weiterhin über Spendenaktionen informiert werden."
        uncheck "Meine Daten sollen nach dem Austritt erhalten bleiben und ich kann für Spendenaufrufe kontaktiert werden"
        expect(data_retention_checkbox).not_to be_checked
        expect(fundraising_checkbox).not_to be_checked
        expect(data_retention_checkbox).not_to be_checked
      end
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
      check "Meine Daten sollen nach dem Austritt erhalten bleiben und ich kann für Spendenaufrufe kontaktiert werden"
      check "Ich möchte weiterhin über Spendenaktionen informiert werden."
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_content "Deine SAC-Mitgliedschaft wurde gekündet."
        role.reload
      end
        .to not_change { person.roles.count }
        .and change { role.terminated }.to(true)
        .and change { role.termination_reason }.from(nil).to(termination_reason)
    end

    it "role validation errors on wizard" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      role.update_columns(created_at: Time.zone.now.beginning_of_year + 3.months)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "SAC-Mitgliedschaft beenden"
      select termination_reason.text
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_css ".alert-danger-alert", text: "Edmund Hillary: Person muss Mitglied sein während der ganzen " \
          "Gültigkeitsdauer der Zusatzsektion."
      end
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
      it "shows an info text" do
        additional_section.update!(mitglied_termination_by_section_only: true)

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
