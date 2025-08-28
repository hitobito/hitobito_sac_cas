# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "Event Signup", :js do
  let(:admin) { people(:admin) }
  let(:root) { groups(:root) }

  before { sign_in(admin) }

  def complete_contact_data
    choose "männlich"
    fill_in "event_participation_contact_data_street", with: "Musterplatz"
    fill_in "event_participation_contact_data_housenumber", with: "42"
    fill_in "Geburtsdatum", with: "01.01.1980"
    fill_in "Mobil",
      with: "+41 79 123 45 56"
    fill_in "event_participation_contact_data_zip_code", with: "40202"
    fill_in "event_participation_contact_data_town", with: "Zürich"
    find(:label, "Land").click
    find(:option, text: "Vereinigte Staaten").click
  end

  context "event" do
    let(:group) { groups(:geschaeftsstelle) }
    let(:event) { Fabricate(:event, groups: [group]) }

    it "has two step wizard" do
      allow_any_instance_of(ActionView::Base).to receive_messages(add_another: false)
      allow_any_instance_of(ActionView::Base).to receive_messages(add_another_label: "")

      visit group_event_path(group_id: group, id: event.id)
      click_on "Anmelden"
      expect(page).to have_css ".stepwizard-step", count: 2
      complete_contact_data
      first(:button, "Weiter").click
      click_on "Anmelden"
      expect(page).to have_content "Teilnahme von Anna Admin in Eventus wurde erfolgreich erstellt"
      expect(admin.reload.address).to eq "Musterplatz 42"
      expect(admin.gender).to eq "m"
      expect(admin.zip_code).to eq "40202"
      expect(admin.town).to eq "Zürich"
      expect(admin.country).to eq "US"
      expect(admin.birthday).to eq Date.new(1980, 1, 1)
      expect(admin.phone_numbers).to have(1).item
      expect(admin.phone_numbers.first.number).to eq "+41 79 123 45 56"
      expect(admin.phone_numbers.first.label).to eq "mobile"
    end
  end

  context "course" do
    let(:group) { groups(:root) }
    let(:event) { Fabricate(:sac_open_course, groups: [group], price_subsidized: 10) }

    it "has multi step wizard without subsidy" do
      visit group_event_path(group_id: group, id: event.id)
      click_on "Anmelden"
      expect(page).to have_css ".stepwizard-step", count: 3
      expect(page).to have_css ".stepwizard-step.is-current", text: "Kontaktangaben"
      expect(page).to have_text "CHF 20"
      complete_contact_data
      first(:button, "Weiter").click
      expect(page).to have_css ".stepwizard-step.is-current", text: "Zusatzdaten"
      first(:button, "Zurück").click
      expect(page).to have_css ".stepwizard-step.is-current", text: "Kontaktangaben"
      first(:button, "Weiter").click
      expect(page).to have_css ".stepwizard-step.is-current", text: "Zusatzdaten"
      first(:button, "Weiter").click
      expect(page).to have_css ".stepwizard-step.is-current", text: "Zusammenfassung"
      first(:button, "Zurück").click
      expect(page).to have_css ".stepwizard-step.is-current", text: "Zusatzdaten"
      first(:button, "Weiter").click
      expect(page).to have_css ".stepwizard-step.is-current", text: "Zusammenfassung"
      expect(page).to have_checked_field("event_participation[newsletter]")
      check "Ja, ich erkläre mich mit den AGB einverstanden"
      check "Ich bestätige, dass ich mindestens 18 Jahre alt bin oder das Einverständnis meiner Erziehungsberechtigten habe"
      click_on "Anmelden"
      expect(page).to have_content "Es wurde eine Voranmeldung erstellt"
    end

    context "with role Mitglied" do
      before do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: groups(:bluemlisalp_mitglieder), person: admin)
        admin.update!(birthday: nil)
      end

      it "has multi step wizard with subsidy checkbox" do
        event.update!(price_subsidized: 6.0)
        visit group_event_path(group_id: group, id: event.id)
        click_on "Anmelden"
        expect(page).to have_css ".stepwizard-step", count: 4
        expect(page).to have_css ".stepwizard-step.is-current", text: "Kontaktangaben"
        complete_contact_data
        first(:button, "Weiter").click
        expect(page).to have_css ".stepwizard-step.is-current", text: "Zusatzdaten"
        first(:button, "Weiter").click
        expect(page).to have_css ".stepwizard-step.is-current", text: "Subventionsbeitrag"
        expect(page).to have_no_text "- Subvention"
        check "Subventionierten Preis von CHF 6.00 beantragen"
        expect(page).to have_text "- Subvention"
        expect(page).to have_text "CHF 6"
        first(:button, "Weiter").click
        expect(page).to have_css ".stepwizard-step.is-current", text: "Zusammenfassung"
        expect(page).to have_text "- Subvention"
        first(:button, "Zurück").click
        expect(page).to have_css ".stepwizard-step.is-current", text: "Subventionsbeitrag"
        uncheck "Subventionierten Preis von CHF 6.00 beantragen"
        expect(page).to have_no_text "- Subvention"
        first(:button, "Weiter").click
        expect(page).to have_css ".stepwizard-step.is-current", text: "Zusammenfassung"
        expect(page).to have_text admin.to_s
        expect(page).to have_no_text "- Subvention"
        click_on "Anmelden"
        expect(page).to have_text "AGB muss akzeptiert werden"
        with_retries do
          check "Ja, ich erkläre mich mit den AGB einverstanden"
          expect(page).to have_checked_field "Ja, ich erkläre mich mit den AGB einverstanden"
        end
        check "Ich bestätige, dass ich mindestens 18 Jahre alt bin oder das Einverständnis meiner Erziehungsberechtigten habe"
        click_on "Anmelden"
        expect(page).to have_content "Es wurde eine Voranmeldung erstellt"
      end

      it "rerenders in correct layout when form is invalid" do
        visit group_event_path(group_id: group, id: event.id)
        click_on "Anmelden"
        expect(page).to have_css ".stepwizard-step", count: 4
        expect(page).to have_css ".stepwizard-step.is-current", text: "Kontaktangaben"

        first(:button, "Weiter").click
        expect(page).to have_css ".stepwizard-step.is-current", text: "Kontaktangaben"
        expect(page).to have_text "Geburtsdatum muss ausgefüllt werden"
        expect(page).to have_css "h2.card-title", text: "Kostenübersicht"
      end
    end
  end
end
