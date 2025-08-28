# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::ParticipantReminderJob do
  include ActiveJob::TestHelper

  let(:event) { Fabricate(:sac_open_course, dates: [Event::Date.new(start_at: 6.weeks.from_now)]) }
  let!(:participation_1) { Fabricate(:event_participation, event:, participant: people(:admin)) }
  let!(:participation_2) { Fabricate(:event_participation, event:, participant: people(:mitglied)) }
  let!(:question) { event.questions.create!(admin: true, question: "test", disclosure: :optional) }

  subject(:job) { described_class.new }

  context "rescheduling" do
    it "reschedules for tomorrow at 5 minutes past midnight" do
      job.perform
      next_job = Delayed::Job.find_by("handler LIKE '%ParticipantReminderJob%'")
      expect(next_job.run_at).to eq(Time.zone.tomorrow + 5.minutes)
    end
  end

  context "both participations have missing answers" do
    before do
      participation_1.answers.update_all(answer: "no")
      participation_2.answers.update_all(answer: "nein")
    end

    it "sends email to both participants" do
      expect { job.perform }
        .to have_enqueued_mail(Event::ParticipantReminderMailer, :reminder).with(participation_1)
        .and have_enqueued_mail(Event::ParticipantReminderMailer, :reminder).with(participation_2)
    end
  end

  context "one participation has missing answers" do
    before do
      participation_1.answers.update_all(answer: "filled out")
      participation_2.answers.update_all(answer: "")
    end

    it "sends email to the participant" do
      expect { job.perform }
        .to have_enqueued_mail(Event::ParticipantReminderMailer, :reminder).once.with(participation_2)
    end
  end

  context "not all answers are filled out" do
    before do
      participation_1.answers.update_all(answer: "filled out")
      participation_2.answers.update_all(answer: "filled out")
      event.questions.create!(admin: true, question: "not filled out yet", disclosure: :optional)
    end

    it "sends email to the participants" do
      expect { job.perform }
        .to have_enqueued_mail(Event::ParticipantReminderMailer, :reminder).twice
    end
  end

  context "event not starting in 6 weeks" do
    before { event.dates.update_all(start_at: 6.weeks.from_now + 1.day) }

    it "doesn't send an email" do
      expect { job.perform }.not_to have_enqueued_mail(Event::ParticipantReminderMailer)
    end
  end

  context "event question not of type 'admin'" do
    before { question.update!(admin: false) }

    it "doesn't send an email" do
      expect { job.perform }.not_to have_enqueued_mail(Event::ParticipantReminderMailer)
    end
  end

  context "states" do
    it "doesn't send an email in closed state" do
      event.update_column(:state, :closed)
      expect { job.perform }.not_to have_enqueued_mail(Event::ParticipantReminderMailer)
    end

    it "doesn't send an email in canceled state" do
      event.update_column(:state, :canceled)
      expect { job.perform }.not_to have_enqueued_mail(Event::ParticipantReminderMailer)
    end
  end
end
