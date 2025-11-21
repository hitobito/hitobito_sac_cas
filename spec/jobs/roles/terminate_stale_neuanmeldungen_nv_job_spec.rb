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

  def create_role(type, group, start_on = Time.zone.now, person = nil)
    Fabricate(group.class.const_get(type).sti_name, {group:, start_on:, person:}.compact_blank)
  end

  it "reschedules for tomorrow at 5 minutes past midnight" do
    job.perform
    next_job = Delayed::Job.find_by("handler like '%TerminateNeuanmeldungenNvJob%'")
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

  it "ignores neuanmeldungen sektion roles starting more than 4 months ago" do
    create_role("Neuanmeldung", neuanmeldungen_sektion, 5.months.ago)
    create_role("NeuanmeldungZusatzsektion", neuanmeldungen_sektion, 5.months.ago, person)
    expect { job.perform }.to not_change { Role.count }
  end
end
