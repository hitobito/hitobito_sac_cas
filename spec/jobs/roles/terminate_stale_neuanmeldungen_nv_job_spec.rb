# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Roles::TerminateStaleNeuanmeldungenNvJob do
  subject(:job) { described_class.new }

  let(:matterhorn) { groups(:matterhorn_mitglieder) }
  let(:neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:neuanmeldungen_nv) { groups(:bluemlisalp_neuanmeldungen_nv) }

  let(:person) { create_role("Mitglied", matterhorn, 1.year.ago).person }

  def create_role(type, group, start_on = Time.zone.now, person = nil, end_on: nil)
    Fabricate(group.class.const_get(type).sti_name, {group:, start_on:, person:, end_on:}.compact_blank)
  end

  it "reschedules for tomorrow at 5 minutes past midnight" do
    job.perform
    next_job = Delayed::Job.find_by("handler like '%TerminateStaleNeuanmeldungenNvJob%'")
    expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
  end

  it "ignores for neuanmeldungen nv roles starting less than 4 months ago" do
    create_role("Neuanmeldung", neuanmeldungen_nv, 3.months.ago)
    create_role("NeuanmeldungZusatzsektion", neuanmeldungen_nv, 3.months.ago, person)
    expect { job.perform }.to not_change { Role.count }
  end

  it "terminates neuanmeldungen nv roles starting more than 4 months ago and deletes open invoices" do
    create_role("Neuanmeldung", neuanmeldungen_nv, 5.months.ago)
    create_role("NeuanmeldungZusatzsektion", neuanmeldungen_nv, 5.months.ago, person)
    expect { job.perform }.to change { Role.count }.by(-2)
  end

  it "ignores neuanmeldungen nv roles starting more than 4 months ago that have been already processed" do
    create_role("Neuanmeldung", neuanmeldungen_nv, 5.months.ago, end_on: 1.day.ago)
    create_role("NeuanmeldungZusatzsektion", neuanmeldungen_nv, 5.months.ago, person, end_on: 1.day.ago)
    expect(job).not_to receive(:terminate_roles_and_cancel_invoices)

    expect { job.perform }.not_to change { Role.count }
  end

  it "ignores terminated neuanmeldungen nv roles starting more than 4 months ago" do
    [
      create_role("Neuanmeldung", neuanmeldungen_nv, 5.months.ago),
      create_role("NeuanmeldungZusatzsektion", neuanmeldungen_nv, 5.months.ago, person)
    ].each { |r| r.update_column(:terminated, true) }

    expect { job.perform }.not_to change { Role.count }
  end

  it "ignores neuanmeldungen sektion roles starting more than 4 months ago" do
    create_role("Neuanmeldung", neuanmeldungen_sektion, 5.months.ago)
    create_role("NeuanmeldungZusatzsektion", neuanmeldungen_sektion, 5.months.ago, person)
    expect { job.perform }.to not_change { Role.count }
  end

  describe "cancelling invoices" do
    let!(:person) { create_role("Neuanmeldung", neuanmeldungen_nv, 5.months.ago).person }

    def create_invoice(person, state: :open, link: groups(:bluemlisalp))
      Fabricate(:sac_membership_invoice, person:, link:, state:)
    end

    it "cancels open invoice" do
      invoice = create_invoice(person)
      expect { job.perform }.to change { Role.count }.by(-1)
        .and change { invoice.reload.state }.from("open").to("cancelled")
    end

    it "cancels all open invoice" do
      invoice = create_invoice(person)
      second_invoice = create_invoice(person)
      expect { job.perform }.to change { Role.count }.by(-1)
        .and change { invoice.reload.state }.from("open").to("cancelled")
        .and change { second_invoice.reload.state }.from("open").to("cancelled")
    end

    it "cancels payed invoice" do
      invoice = create_invoice(person, state: :payed)
      expect { job.perform }.to change { Role.count }.by(-1)
        .and change { invoice.reload.state }.from("payed").to("cancelled")
    end

    it "does not cancel invoice in another group" do
      invoice = create_invoice(person, link: groups(:matterhorn))
      expect { job.perform }.to change { Role.count }.by(-1)
        .and not_change { invoice.reload.state }
    end

    it "does not cancel invoice in error state" do
      invoice = create_invoice(person, state: :error)
      expect { job.perform }.to change { Role.count }.by(-1)
        .and not_change { invoice.reload.state }
    end
  end
end
