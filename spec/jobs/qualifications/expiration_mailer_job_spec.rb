# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Qualifications::ExpirationMailerJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.new }

  let(:person) { people(:mitglied) }
  let!(:qualification) do
    person.qualifications.create!(
      qualification_kind: qualification_kinds(:ski_leader),
      start_at: "2000-01-01".to_date,
      finish_at: finish_at
    )
  end

  context "scheduling" do
    let(:finish_at) { "2000-12-01".to_date }

    before { travel_to "2000-11-01".to_date }

    it "reschedules daily for tomorrow at 5 minutes past midnight" do
      job.perform
      next_job = Delayed::Job.find_by("handler like '%ExpirationMailerJob%'")
      expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
    end
  end

  context "qualification expires today" do
    let(:finish_at) { "2000-01-01".to_date }

    before { travel_to "2000-01-01".to_date }

    it "mails a reminder" do
      expect(Qualifications::ExpirationMailer).to receive(:reminder).with(:today,
        person.id).and_call_original
      expect { job.perform }.to have_enqueued_mail(Qualifications::ExpirationMailer).once
    end

    it "does not mail a reminder if another valid qualification is still active" do
      person.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: "2000-01-01".to_date,
        finish_at: "2001-06-01".to_date
      )

      expect { job.perform }.not_to have_enqueued_mail(Qualifications::ExpirationMailer)
    end
  end

  context "qualification expires next year" do
    let(:finish_at) { "2001-12-01".to_date }

    before { travel_to "2000-12-31".to_date }

    it "mails a reminder" do
      # second qualification with same finish_at. only one email is sent
      person.qualifications.create!(
        qualification_kind: qualification_kinds(:snowboard_leader),
        start_at: "2000-01-01".to_date,
        finish_at: finish_at
      )

      expect(Qualifications::ExpirationMailer).to receive(:reminder).with(:next_year,
        person.id).and_call_original
      expect { job.perform }.to have_enqueued_mail(Qualifications::ExpirationMailer).once
    end
  end

  context "qualification expires year after next year" do
    let(:finish_at) { "2002-06-01".to_date }

    before { travel_to "2000-12-31".to_date }

    it "mails a reminder" do
      expect(Qualifications::ExpirationMailer).to receive(:reminder).with(:year_after_next_year,
        person.id).and_call_original
      travel_to "2000-12-31".to_date

      expect { job.perform }.to have_enqueued_mail(Qualifications::ExpirationMailer).once
    end
  end

  context "qualification expires in 3 years" do
    let(:finish_at) { "2003-06-01".to_date }

    before { travel_to "2000-12-31".to_date }

    it "does not mail a reminder" do
      expect(Qualifications::ExpirationMailer).to receive(:reminder).never
      expect { job.perform }.not_to have_enqueued_mail(Qualifications::ExpirationMailer)
    end
  end

  context "with multiple people" do
    let(:admin) { people(:admin) }
    let(:finish_at) { "2001-06-01".to_date }

    it "mails a reminder to everyone with an email" do
      admin.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: "2000-01-01".to_date,
        finish_at: finish_at
      )
      other = Fabricate(:person, email: nil)
      other.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: "2000-01-01".to_date,
        finish_at: finish_at
      )
      travel_to "2000-12-31".to_date

      expect { job.perform }.to have_enqueued_mail(Qualifications::ExpirationMailer).twice
    end

    it "does not care about qualifications expired long ago" do
      admin.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: "2000-01-01".to_date,
        finish_at: finish_at
      )
      travel_to "2020-12-31".to_date
      expect { job.perform }.not_to have_enqueued_mail(Qualifications::ExpirationMailer)
    end
  end
end
