# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Participation, :js do
  include ActiveJob::TestHelper

  let(:admin) { people(:admin) }
  let(:participant) { people(:mitglied) }
  let(:event) { Fabricate(:sac_open_course) }
  let(:participation) { Fabricate(:event_participation, event:, person: participant, price_category: "price_member", price: 10, application_id: -1) }

  context "as participant" do
    before do
      sign_in(participant)
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
    end

    it "doesn't show invoice button" do
      expect(page).not_to have_button("Rechnung erstellen")
    end

    it "does show price information" do
      expect(page).to have_text("Mitgliederpreis")
    end

    it "does show j_s price information for j_s course" do
      event.kind.kind_category.update_column(:j_s_course, true)
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
      expect(page).to have_text("J&S P-Mitgliederpreis")
    end

    it "does not display checkbox option to not send email" do
      event.update_columns(applications_cancelable: true, state: "application_open")
      event.dates.first.update_column(:start_at, 10.days.from_now)
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
      within(".btn-toolbar") do
        click_on "Abmelden"
      end
      expect(page).to have_no_text "E-Mail an Teilnehmer/in senden"
    end

    it "does not display radio buttons for annulation invoice" do
      event.update_columns(applications_cancelable: true, state: "application_open")
      event.dates.first.update_column(:start_at, 10.days.from_now)
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
      within(".btn-toolbar") do
        click_on "Abmelden"
      end
      expect(page).to have_no_text "Annullationskostenrechnung gem. Reglement"
      expect(page).to have_no_text "Annullationskostenrechnung mit einem benutzerdefinierten Betrag"
      expect(page).to have_no_text "Keine Annullationskostenrechnung"
    end
  end

  context "as admin" do
    before { sign_in(admin) }

    it "creates invoice after accepting confirm alert" do
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
      accept_confirm { click_on("Rechnung erstellen") }
      expect(page).to have_css(".alert", text: "Rechnung wurde erfolgreich erstellt.")
    end

    it "doesn't create invoice when rejecting confirm alert" do
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
      dismiss_confirm { click_on("Rechnung erstellen") }
      expect(page).not_to have_css(".alert")
    end

    context "cancel" do
      before do
        visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
        within(".btn-toolbar") do
          click_on "Abmelden"
        end
        within(".popover") do
          fill_in "Begründung", with: "Some Reason"
        end
      end

      it "can cancel participation and supply a reason in popover" do
        expect do
          within(".popover") do
            click_on "Abmelden"
          end
          expect(page).to have_content "Edmund Hillary wurde abgemeldet."
        end.to have_enqueued_mail(Event::ParticipationCanceledMailer, :confirmation).once
      end

      it "can cancel participation without sending email" do
        expect do
          within(".popover") do
            uncheck "E-Mail an Teilnehmer/in senden"
            click_on "Abmelden"
          end
          expect(page).to have_content "Edmund Hillary wurde abgemeldet."
        end.not_to have_enqueued_mail(Event::ParticipationCanceledMailer, :confirmation)
      end
    end

    context "summon" do
      before do
        event.update_column(:state, :ready)
        participation.update_column(:state, :assigned)
        visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
        click_on "Aufbieten"
        expect(page).to have_text "Willst du diese/n Teilnehmer/in wirklich aufbieten?"
      end

      it "does send mail when selecting send email true" do
        expect do
          click_on "Aufbieten und E-Mail senden"
          expect(page).to have_text "Edmund Hillary wurde aufgeboten."
        end.to have_enqueued_mail(Event::ParticipationMailer, :summon).once
      end

      it "does not send mail when selecting send email false" do
        expect do
          click_on "Aufbieten ohne E-Mail"
          expect(page).to have_text "Edmund Hillary wurde aufgeboten."
        end.not_to have_enqueued_mail(Event::ParticipationMailer, :summon)
      end
    end
  end
end
