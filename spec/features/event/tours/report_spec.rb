# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "event/tours/reports", js: true do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:report) { event_reports(:section_tour_report) }
  let!(:recipient) { people(:mitglied) }

  before do
    event.update_column(:state, "ready")
    sign_in(user)
    create_recipient_role(recipient)
  end

  def create_recipient_role(person)
    Fabricate(Group::SektionsTourenUndKurse::Tourenchef.name.to_sym,
      group: groups(:bluemlisalp_touren_und_kurse),
      person:,
      start_on: 1.year.ago,
      end_on: 1.year.from_now)
  end

  def visit_report
    visit edit_group_event_report_path(group, event)
  end

  context "draft status" do
    before { visit_report }

    it "shows forward option and recipient dropdown, but no reject option" do
      expect(page).to have_unchecked_field("Zur Freigabe einreichen an")
      expect(page).to have_select("Empfänger/-in")
      expect(page).not_to have_unchecked_field("Ablehnen")
    end

    it "shows validation error and marks field red when forwarding without recipient" do
      choose "Zur Freigabe einreichen an"
      click_button "Speichern"

      expect(page).to have_selector("#error_explanation", text: "Empfänger/-in muss ausgefüllt werden")
      expect(page).to have_css("select.is-invalid")
    end

    it "successfully forwards report to review status" do
      choose "Zur Freigabe einreichen an"
      select recipient.full_name, from: "Empfänger/-in"
      click_button "Speichern"

      expect(page).to have_current_path(group_event_path(group, event))
      expect(report.reload.status).to eq(:review)
      expect(report.reload.submitter).to eq(user)
    end
  end

  context "review status" do
    before do
      report.update_columns(submitted_at: 1.day.ago, submitter_id: recipient.id)
      visit_report
    end

    it "shows forward and reject options with recipient dropdown" do
      expect(page).to have_unchecked_field("Zur Auszahlung freigeben an")
      expect(page).to have_unchecked_field("Ablehnen")
      expect(page).to have_select("Empfänger/-in")
    end

    it "shows validation error and marks field red when forwarding without recipient" do
      choose "Zur Auszahlung freigeben an"
      click_button "Speichern"

      expect(page).to have_selector("#error_explanation", text: "Empfänger/-in muss ausgefüllt werden")
      expect(page).to have_css("select.is-invalid")
    end

    it "successfully forwards report to approved status" do
      choose "Zur Auszahlung freigeben an"
      select recipient.full_name, from: "Empfänger/-in"
      click_button "Speichern"

      expect(page).to have_current_path(group_event_path(group, event))
      expect(report.reload.status).to eq(:approved)
      expect(report.reload.approver).to eq(user)
    end

    it "successfully rejects report back to draft status" do
      choose "Ablehnen"
      click_button "Speichern"

      expect(page).to have_current_path(group_event_path(group, event))
      expect(report.reload.status).to eq(:draft)
    end
  end

  context "approved status" do
    before do
      report.update_columns(
        submitted_at: 2.days.ago, submitter_id: recipient.id,
        approved_at: 1.day.ago, approver_id: recipient.id
      )
      visit_report
    end

    it "shows forward and reject options but no recipient dropdown" do
      expect(page).to have_unchecked_field("Auszahlung erfasst")
      expect(page).to have_unchecked_field("Ablehnen")
      expect(page).not_to have_select("Empfänger/-in")
    end

    it "successfully records payout and transitions to closed status" do
      choose "Auszahlung erfasst"
      click_button "Speichern"

      expect(page).to have_current_path(group_event_path(group, event))
      expect(report.reload.status).to eq(:closed)
      expect(report.reload.payer).to eq(user)
    end

    it "successfully rejects report back to review status" do
      choose "Ablehnen"
      click_button "Speichern"

      expect(page).to have_current_path(group_event_path(group, event))
      expect(report.reload.status).to eq(:review)
    end
  end
end
