# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Roles::TerminateTourenleiterJob do
  subject(:job) { described_class.new }

  context "rescheduling" do
    it "reschedules for tomorrow  at 5 minutes past midnight" do
      job.perform
      next_job = Delayed::Job.find_by("handler like '%TerminateTourenleiterJob%'")
      expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
    end
  end

  context "with role" do
    let(:group) { groups(:matterhorn_touren_und_kurse) }
    let(:qualification) { Fabricate(:qualification, qualification_kind: qualification_kinds(:ski_leader)) }
    let(:yesterday) { Time.zone.yesterday.end_of_day.to_s(:db) }

    let(:person) { qualification.person }
    let!(:role) { Fabricate(Group::SektionsTourenUndKurse::Tourenleiter.sti_name, person: person, group: group) }

    it "noops if qualification is active" do
      expect { job.perform }.to not_change { person.roles.count }
    end

    it "noops if qualification never expires" do
      qualification.update!(finish_at: nil)
      expect { job.perform }.to not_change { person.roles.count }
    end

    it "noops if qualification expires today" do
      qualification.update!(finish_at: Time.zone.today)
      expect { job.perform }.to not_change { person.roles.count }
    end

    it "terminates role if qualification expired yesterday" do
      qualification.update!(finish_at: Time.zone.yesterday)
      expect { job.perform }.to change { person.roles.count }.by(-1)
      expect(Role.with_deleted.find_by(id: role.id).deleted_at.to_date).to eq Time.zone.yesterday
    end

    it "terminates role if qualification was removed" do
      qualification.destroy!
      expect { job.perform }.to change { person.roles.count }.by(-1)
      expect(Role.with_deleted.find_by(id: role.id).deleted_at.to_date).to eq Time.zone.yesterday
    end
  end
end
