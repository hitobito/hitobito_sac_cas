# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::BackupMitgliederScheduleJob do
  subject(:job) { described_class.new }

  let(:relevant_groups) { Group.where(type: [Group::Sektion, Group::Ortsgruppe].map(&:sti_name)) }

  context "rescheduling" do
    it "reschedules for tomorrow at 5 minutes past midnight" do
      job.perform
      next_job = Delayed::Job.find_by("handler like '%BackupMitgliederScheduleJob%'")
      expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
    end
  end

  context "perform" do
    it "only iterates over relevant groups" do
      relevant_groups.each do |group|
        expect(Export::BackupMitgliederExportJob).to receive(:new)
          .with(group.id)
          .and_call_original
      end

      expect do
        job.perform
      end.to change {
               Delayed::Job.where("handler like '%BackupMitgliederExportJob%'").count
             }.by(relevant_groups.length)

      relevant_groups.each do |group|
        expect(Delayed::Job.where("handler like '%group_id: 935587148%'")).to be_present
      end
    end
  end
end
