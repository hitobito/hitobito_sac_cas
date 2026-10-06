# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::SacMemberships::InvoicePayedJob do
  let(:date) { Time.zone.today.next_year.end_of_year }
  let(:person) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:log_entry) { HitobitoLogEntry.last }

  subject(:job) { described_class.new(person.id, group.id, date.year) }

  it "executes membership manager update membership status" do
    expect_any_instance_of(Invoices::SacMemberships::MembershipManager)
      .to receive(:update_membership_status)

    job.perform
  end

  context "with missing records" do
    it "creates error log entry if person does not exist" do
      job = described_class.new(-1, group.id, date.year)

      expect_any_instance_of(Invoices::SacMemberships::MembershipManager)
        .not_to receive(:update_membership_status)
      expect { job.perform }.to change { HitobitoLogEntry.count }.by(1)

      expect(log_entry.level).to eq "error"
      expect(log_entry.category).to eq "rechnungen"
      expect(log_entry.subject).to be_nil
      expect(log_entry.message).to eq "Eingegangene Zahlung der Mitgliedschaftsrechnung " \
        "#{date.year} konnte nicht verarbeitet werden, da die Person (ID -1) oder die " \
        "Gruppe (ID #{group.id}) nicht gefunden wurde."
    end

    it "creates error log entry if group does not exist" do
      job = described_class.new(person.id, -1, date.year)

      expect { job.perform }.to change { HitobitoLogEntry.count }.by(1)

      expect(log_entry.level).to eq "error"
      expect(log_entry.subject).to eq person
      expect(log_entry.message).to include "Gruppe (ID -1)"
    end
  end

  context "when running via worker" do
    before do
      allow_any_instance_of(Invoices::SacMemberships::MembershipManager)
        .to receive(:update_membership_status).and_raise(ArgumentError, "ouch")
    end

    it "creates error log entry on every failed attempt" do
      delayed_job = job.enqueue!

      expect do
        Delayed::Worker.new.run(delayed_job)
        Delayed::Worker.new.run(delayed_job.reload)
      end.to change { HitobitoLogEntry.count }.by(2)

      expect(log_entry.level).to eq "error"
      expect(log_entry.category).to eq "rechnungen"
      expect(log_entry.subject).to eq person
      expect(log_entry.message).to eq "Eingegangene Zahlung der Mitgliedschaftsrechnung " \
        "#{date.year} für SAC Blüemlisalp konnte nicht verarbeitet werden."
      expect(log_entry.payload).to eq "ArgumentError: ouch"
    end
  end
end
