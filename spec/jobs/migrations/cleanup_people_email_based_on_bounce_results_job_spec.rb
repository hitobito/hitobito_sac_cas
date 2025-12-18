# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Migrations::CleanupPeopleEmailBasedOnBounceResultsJob do
  let(:job) { described_class.new }
  let(:csv_fixture_data) { CSV.read(Wagons.find("sac_cas").root.join("spec", "fixtures", "files", "bounce_results.csv"), col_sep: ",", headers: true) }
  let(:abacus_client) { instance_double(Invoices::Abacus::Client) }

  before do
    allow(job).to receive(:csv_data).and_return(csv_fixture_data)
    allow(job).to receive(:abacus_client).and_return(abacus_client)
    allow(abacus_client).to receive(:batch).and_yield
    allow(abacus_client).to receive(:batch_context_object=)
    allow(abacus_client).to receive(:update)

    @soft_confirmed = Fabricate(:person, email: "soft-confirmed@example.com", confirmed_at: 10.days.ago)
    @hard_confirmed = Fabricate(:person, email: "hard-confirmed@example.com", confirmed_at: 10.days.ago)
    @soft_print = Fabricate(:person, email: "soft-print@example.com", correspondence: "print")
    @hard_print = Fabricate(:person, email: "hard-print@example.com", correspondence: "print")
    @soft_digital = Fabricate(:person, email: "soft-digital@example.com", correspondence: "digital")
    @hard_digital = Fabricate(:person, email: "hard-digital@example.com", correspondence: "digital")
    @soft_unconfirmed = Fabricate(:person, email: "soft-unconfirmed@example.com", confirmed_at: nil)
    @hard_unconfirmed = Fabricate(:person, email: "hard-unconfirmed@example.com", confirmed_at: nil)
  end

  it "correctly updates confirmed_at" do
    expect(@soft_confirmed.confirmed_at).to be_present
    expect(@hard_confirmed.confirmed_at).to be_present
    expect(@soft_unconfirmed.confirmed_at).to be_nil
    expect(@hard_unconfirmed.confirmed_at).to be_nil

    job.perform

    expect(@soft_confirmed.reload.confirmed_at).to be_present
    expect(@hard_confirmed.reload.confirmed_at).to be_nil
    expect(@soft_unconfirmed.reload.confirmed_at).to be_nil
    expect(@hard_unconfirmed.reload.confirmed_at).to be_nil
  end

  it "correctly updates correspondence" do
    expect(@soft_print.correspondence).to eq("print")
    expect(@hard_print.correspondence).to eq("print")
    expect(@soft_digital.correspondence).to eq("digital")
    expect(@hard_digital.correspondence).to eq("digital")

    job.perform

    expect(@soft_print.reload.correspondence).to eq("print")
    expect(@hard_print.reload.correspondence).to eq("print")
    expect(@soft_digital.reload.correspondence).to eq("print")
    expect(@hard_digital.reload.correspondence).to eq("print")
  end

  it "correctly updates email" do
    soft_bounced = [
      @soft_confirmed,
      @soft_print,
      @soft_digital,
      @soft_unconfirmed
    ]

    hard_bounced = [
      @hard_confirmed,
      @hard_print,
      @hard_digital,
      @hard_unconfirmed
    ]

    (soft_bounced + hard_bounced).each { |p| expect(p.email).to be_present }

    job.perform

    soft_bounced.each { |p| expect(p.reload.email).to be_present }
    hard_bounced.each { |p| expect(p.reload.email).to be_nil }
  end

  it "sends changed people to abacus" do
    changed = [
      @soft_digital,
      @hard_confirmed,
      @hard_print,
      @hard_digital,
      @hard_unconfirmed
    ]
    changed.each do |p|
      expect(Invoices::Abacus::Subject).to receive(:new).with(p).and_call_original
    end

    unchanged = [
      @soft_print,
      @soft_confirmed,
      @soft_unconfirmed
    ]

    unchanged.each do |p|
      expect(Invoices::Abacus::Subject).to_not receive(:new).with(p).and_call_original
    end

    job.perform
  end
end
