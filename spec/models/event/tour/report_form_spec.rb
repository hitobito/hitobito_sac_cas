# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Tour::ReportForm do
  let(:event) { events(:section_tour) }
  let(:report) { event_reports(:section_tour_report) }
  let(:participation) do
    Fabricate(Event::Role::Participant.name.to_sym,
      participation: Fabricate(:event_participation, participant: people(:mitglied), event: event)).participation
  end
  let(:current_user) { people(:admin) }
  let(:form) { described_class.new(report, current_user) }
  let(:recipient) { people(:mitglied) }

  it "assigns attributes from report, defaulting status_action to keep" do
    expect(form.status_action).to eq "keep"
  end

  it "assigns attributes from report" do
    expect(form.review).to eq(report.review)
    expect(form.remarks).to eq(report.remarks)
  end

  describe "#save" do
    it "persists changed attributes to the report" do
      form.review = "Updated review"
      form.remarks = "Some remarks"

      expect { form.save }
        .to change { report.reload.review }.to("Updated review")
        .and change { report.reload.remarks }.to("Some remarks")
    end

    it "perists changed attributes to the participations" do
      form.participations_attributes = {
        participation.id.to_s => {
          state: "attended",
          means_of_transport: "legs"
        }
      }

      expect { form.save }
        .to change { participation.reload.state }.from("assigned").to("attended")
        .and change { participation.reload.means_of_transport }.from(nil).to("legs")
    end
  end

  describe "#participations" do
    [:rejected, :applied, :unconfirmed].each do |state|
      it "does not include participations in state #{state}" do
        participation.update_column(:state, state)

        expect(form.participations).not_to include(participation)
      end
    end
  end

  describe "#editable_participation_state?" do
    it "returns true for an editable state" do
      participation.update_columns(state: "assigned")
      expect(form.editable_participation_state?(participation)).to be true
    end

    it "returns false for a non editable state" do
      participation.update_columns(state: "canceled")
      expect(form.editable_participation_state?(participation)).to be false
    end
  end

  describe "#assert_participation_states_editable" do
    it "is valid when participation is in an editable state" do
      participation.update_columns(state: "assigned")
      form.participations_attributes = {
        participation.id.to_s => {
          state: "attended"
        }
      }

      expect(form).to be_valid
    end

    it "is invalid when participation is in a non editable state" do
      participation.update_columns(state: "canceled")
      form.participations_attributes = {
        participation.id.to_s => {
          state: "attended"
        }
      }

      expect(form).not_to be_valid
    end
  end

  describe "#possible_mail_recipients" do
    let(:touren_und_kurse) { groups(:bluemlisalp_touren_und_kurse) }
    let(:role_attrs) { {start_on: 1.year.ago, end_on: 1.year.from_now} }

    it "includes people with Tourenchef role in the tour's section" do
      Fabricate(Group::SektionsTourenUndKurse::Tourenchef.name.to_sym,
        group: touren_und_kurse, person: recipient, **role_attrs)

      expect(form.possible_mail_recipients).to include(recipient)
    end

    it "excludes people from a different section" do
      Fabricate(Group::SektionsTourenUndKurse::Tourenchef.name.to_sym,
        group: groups(:matterhorn_touren_und_kurse), person: recipient, **role_attrs)

      expect(form.possible_mail_recipients).not_to include(recipient)
    end
  end

  describe "#assert_mail_recipient_present_when_forwarding" do
    it "is valid when status_action is keep" do
      form.status_action = "keep"

      expect(form).to be_valid
    end

    it "is invalid when forwarding from draft without recipient" do
      form.status_action = "forward"
      form.mail_recipient_id = nil

      expect(form).not_to be_valid
      expect(form.errors[:mail_recipient_id]).to include("muss ausgefüllt werden")
    end

    it "is valid when forwarding from approved without recipient (no dropdown)" do
      report.update_column(:submitted_at, 1.day.ago)
      report.update_column(:approved_at, 1.day.ago)
      form.status_action = "forward"
      form.mail_recipient_id = nil

      expect(form).to be_valid
    end
  end

  describe "#save with status_action" do
    it "sets submitted_at and submitter_id when forwarding from draft" do
      form.status_action = "forward"
      form.mail_recipient_id = recipient.id

      expect { form.save }
        .to change { report.reload.submitted_at }.from(nil)
        .and change { report.reload.submitter_id }.to(current_user.id)
    end

    it "enqueues submitted email when forwarding from draft" do
      form.status_action = "forward"
      form.mail_recipient_id = recipient.id

      expect { form.save }.to have_enqueued_mail(Event::TourReportMailer, :submitted)
    end

    it "sets approved_at and approver_id when forwarding from review" do
      report.update_column(:submitted_at, 1.day.ago)
      report.update_column(:submitter_id, recipient.id)
      form.status_action = "forward"
      form.mail_recipient_id = recipient.id

      expect { form.save }
        .to change { report.reload.approved_at }.from(nil)
        .and change { report.reload.approver_id }.to(current_user.id)
    end

    it "enqueues approved email when forwarding from review" do
      report.update_columns(submitted_at: 1.day.ago, submitter_id: recipient.id)
      form.status_action = "forward"
      form.mail_recipient_id = recipient.id

      expect { form.save }.to have_enqueued_mail(Event::TourReportMailer, :approved)
    end

    it "sets paid_at and payer_id when forwarding from approved" do
      report.update_columns(submitted_at: 1.day.ago, submitter_id: recipient.id,
        approved_at: 1.day.ago, approver_id: recipient.id)
      form.status_action = "forward"

      expect { form.save }
        .to change { report.reload.paid_at }.from(nil)
        .and change { report.reload.payer_id }.to(current_user.id)
    end

    it "enqueues payout_recorded email when forwarding from approved" do
      report.update_columns(submitted_at: 1.day.ago, submitter_id: recipient.id,
        approved_at: 1.day.ago, approver_id: recipient.id)
      form.status_action = "forward"

      expect { form.save }.to have_enqueued_mail(Event::TourReportMailer, :payout_recorded)
    end

    it "clears submitted_at and submitter_id when rejecting from review" do
      report.update_columns(submitted_at: 1.day.ago, submitter_id: recipient.id)
      form.status_action = "reject"

      expect { form.save }
        .to change { report.reload.submitted_at }.to(nil)
        .and change { report.reload.submitter_id }.to(nil)
    end

    it "enqueues rejected email when rejecting from review" do
      report.update_columns(submitted_at: 1.day.ago, submitter_id: recipient.id)
      form.status_action = "reject"

      expect { form.save }.to have_enqueued_mail(Event::TourReportMailer, :rejected)
    end

    it "clears approved_at and approver_id when rejecting from approved" do
      report.update_columns(submitted_at: 1.day.ago, submitter_id: recipient.id,
        approved_at: 1.day.ago, approver_id: recipient.id)
      form.status_action = "reject"

      expect { form.save }
        .to change { report.reload.approved_at }.to(nil)
        .and change { report.reload.approver_id }.to(nil)
    end

    it "enqueues payout_rejected email when rejecting from approved" do
      report.update_columns(submitted_at: 1.day.ago, submitter_id: recipient.id,
        approved_at: 1.day.ago, approver_id: recipient.id)
      form.status_action = "reject"

      expect { form.save }.to have_enqueued_mail(Event::TourReportMailer, :payout_rejected)
    end

    it "does not enqueue email when keeping status" do
      form.status_action = "keep"

      expect { form.save }.not_to have_enqueued_mail(Event::TourReportMailer)
    end
  end

  describe "#tour_completed?" do
    it "returns false when tour is in progress states" do
      expect(form.tour_completed?).to be_falsey
    end

    it "returns true when tour is ready" do
      event.update_column(:state, :ready)

      expect(form.tour_completed?).to be_truthy
    end

    it "returns true when tour is closed" do
      event.update_column(:state, :closed)

      expect(form.tour_completed?).to be_truthy
    end
  end
end
