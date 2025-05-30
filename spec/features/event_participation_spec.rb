# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe :event_participation, js: true do
  subject { page }

  let(:person) { people(:mitglied) }
  let(:event) { Fabricate(:event, application_opening_at: 5.days.ago, groups: [group]) }
  let(:group) { person.roles.first.group }

  before do
    sign_in(person)
  end

  def complete_contact_data
    choose "männlich"
    fill_in "event_participation_contact_data_street", with: "Musterplatz"
    fill_in "event_participation_contact_data_housenumber", with: "23"
    fill_in "Geburtsdatum", with: "01.01.1980"
    fill_in "Mobil",
      with: "+41 79 123 45 56"
    fill_in "event_participation_contact_data_zip_code", with: "40202"
    fill_in "event_participation_contact_data_town", with: "Zürich"
    find(:label, "Land").click
    find(:option, text: "Vereinigte Staaten").click
  end

  it "creates an event participation" do
    visit group_event_path(group_id: group, id: event)

    click_link("Anmelden")

    complete_contact_data
    first(:button, "Weiter").click

    fill_in("Kommentar", with: "Wichtige Bemerkungen über meine Teilnahme")

    expect do
      click_button("Anmelden")
      expect(page).to have_text("Teilnahme von #{person.full_name} in #{event.name} wurde " \
                                "erfolgreich erstellt. Bitte überprüfe die Kontaktdaten und " \
                                "passe diese gegebenenfalls an.")
    end.to change { Event::Participation.count }.by(1)

    is_expected.to have_text("Wichtige Bemerkungen über meine Teilnahme")
    is_expected.to have_selector("dt", text: "Anzahl Mitglieder-Jahre")
    # Match exact text to check for absence of self_employed label
    is_expected.to have_selector("tr", text: /^Teilnehmer\/-in$/)

    participation = Event::Participation.find_by(event: event, person: person)

    expect(participation).to be_present
  end

  it "shows phone number validation error if none are filled" do
    visit group_event_path(group_id: group, id: event)

    click_link("Anmelden")

    complete_contact_data

    fill_in "Mobil", with: ""

    first(:button, "Weiter").click

    expect(page).to have_text("Mindestens eine Telefonnummer muss aufgefüllt werden")
  end

  describe "canceling participation" do
    let(:group) { groups(:root) }
    let(:application) { Fabricate(:event_application, priority_1: event, priority_2: event) }
    let(:participation) { Fabricate(:event_participation, event: event, person: person, application: application, price: 20, price_category: 0) }
    let(:event) { Fabricate(:sac_course, application_opening_at: 5.days.ago, groups: [group], applications_cancelable: true) }

    before do
      participation.update!(state: :assigned)
      event.update(applications_cancelable: true)
      event.dates.first.update_columns(start_at: 2.days.from_now)
    end

    context "on event" do
      it "requires a reason when canceling" do
        visit group_event_path(group_id: group, id: event)
        click_button "Abmelden"
        within(".popover-body") { click_on "Abmelden" }
        expect(find_field("Begründung").native.attribute("validationMessage")).to match(/Please fill (out|in) this field./)
      end

      it "can cancel with reason" do
        visit group_event_path(group_id: group, id: event)
        click_button "Abmelden"
        fill_in "Begründung", with: "Krank"
        within(".popover-body") { click_on "Abmelden" }
        expect(page).not_to have_button "Abmelden"
        expect(page).not_to have_css(".popover-body")
      end
    end

    context "on participation" do
      it "requires a reason when canceling" do
        visit group_event_participation_path(group_id: group, event_id: event, id: participation.id)
        click_button "Abmelden"
        within(".popover-body") { click_on "Abmelden" }
        expect(find_field("Begründung").native.attribute("validationMessage")).to match(/Please fill (out|in) this field./)
      end

      it "shows cancellation cost in hint text" do
        visit group_event_participation_path(group_id: group, event_id: event, id: participation.id)
        click_button "Abmelden"
        within(".popover-body") do
          expect(page).to have_text("Bist du sicher, dass du mit der Abmeldung fortfahren möchtest? " \
                                    "Eine Abmeldung kann nicht rückgängig gemacht werden. " \
                                    "Mit der Abmeldung werden Bearbeitungs- und Annullationsgebühren in der Höhe von CHF 20.0 in Rechnung gestellt.")
        end
      end

      it "does not show cancellation cost for participation with status applied" do
        participation.update!(state: :applied)
        visit group_event_participation_path(group_id: group, event_id: event, id: participation.id)
        click_button "Abmelden"
        within(".popover-body") do
          expect(page).to have_no_text("Bist du sicher, dass du mit der Abmeldung fortfahren möchtest?")
        end
      end

      it "shows cancellation cost of zero in hint text if participation does not have a price associated" do
        participation.update!(price: 0)
        visit group_event_participation_path(group_id: group, event_id: event, id: participation.id)
        click_button "Abmelden"
        within(".popover-body") do
          expect(page).to have_text("Bist du sicher, dass du mit der Abmeldung fortfahren möchtest? " \
                                    "Eine Abmeldung kann nicht rückgängig gemacht werden. " \
                                    "Mit der Abmeldung werden Bearbeitungs- und Annullationsgebühren in der Höhe von CHF 0.0 in Rechnung gestellt.")
        end
      end

      it "can cancel with reason" do
        visit group_event_participation_path(group_id: group, event_id: event, id: participation.id)
        click_button "Abmelden"
        fill_in "Begründung", with: "Krank"
        within(".popover-body") { click_on "Abmelden" }
        expect(page).not_to have_button "Abmelden"
        expect(page).not_to have_css(".popover-body")
      end
    end
  end
end
