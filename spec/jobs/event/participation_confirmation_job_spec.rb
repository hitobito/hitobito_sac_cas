# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::ParticipationConfirmationJob do
  include ActiveJob::TestHelper

  let(:group) { groups(:bluemlisalp) }

  let(:participant) { person }
  let(:person) { people(:mitglied) }

  let(:application) { Fabricate(:event_application, priority_1: event, priority_2: event) }
  let(:participation) do
    Fabricate(:event_participation, event: event, participant: person, application: application)
  end

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds", "custom_contents.rb")]
  end

  subject { Event::ParticipationConfirmationJob.new(participation) }

  describe "Event sends directly" do
    let(:event) do
      Fabricate(:event,
        application_opening_at: 5.days.ago,
        groups: [group],
        applications_cancelable: true)
    end

    it "sends event via regular unconfirmed email" do
      expect(Event::ParticipationMailer)
        .to receive(:confirmation).with(participation).and_call_original
      expect { subject.perform }
        .to change { ActionMailer::Base.deliveries.size }.by(1)
        .and not_have_enqueued_mail(Event::CourseParticipationMailer, :confirmation)
    end
  end

  describe "Event::Course uses Event::CourseParticipationMailer" do
    let(:group) { groups(:root) }

    let(:event) do
      Fabricate(:sac_course,
        application_opening_at: 5.days.ago,
        groups: [group],
        applications_cancelable: true)
    end

    before do
      expect(Event::ParticipationMailer).not_to receive(:confirmation)
    end

    it "sends course specific unconfirmed email" do
      expect { subject.perform }
        .to have_enqueued_mail(Event::CourseParticipationMailer, :confirmation)
        .with(participation, "course_application_confirmation_unconfirmed")
        .and not_change { ActionMailer::Base.deliveries.size }
    end

    it "sends course specific assigned email" do
      participation.update!(state: :assigned)
      expect { subject.perform }
        .to have_enqueued_mail(Event::CourseParticipationMailer, :confirmation)
        .with(participation, "course_application_confirmation_assigned")
        .and not_change { ActionMailer::Base.deliveries.size }
    end

    it "sends course specific applied email" do
      participation.update!(state: :applied)
      expect { subject.perform }
        .to have_enqueued_mail(Event::CourseParticipationMailer, :confirmation)
        .with(participation, "course_application_confirmation_applied")
        .and not_change { ActionMailer::Base.deliveries.size }
    end
  end

  describe "Event::Tour uses Event::TourParticipationMailer" do
    let(:group) { groups(:bluemlisalp) }

    let(:event) do
      Fabricate(:sac_tour,
        application_opening_at: 5.days.ago,
        groups: [group],
        applications_cancelable: true)
    end

    before do
      expect(Event::ParticipationMailer).not_to receive(:confirmation)
    end

    it "sends course specific unconfirmed email" do
      expect { subject.perform }
        .to have_enqueued_mail(Event::TourParticipationMailer, :confirmation)
        .with(participation, "event_tour_application_confirmation_unconfirmed")
        .and not_change { ActionMailer::Base.deliveries.size }
    end

    it "sends course specific assigned email" do
      participation.update!(state: :assigned)
      expect { subject.perform }
        .to have_enqueued_mail(Event::TourParticipationMailer, :confirmation)
        .with(participation, "event_tour_application_confirmation_assigned")
        .and not_change { ActionMailer::Base.deliveries.size }
    end

    it "sends course specific applied email" do
      participation.update!(state: :applied)
      expect { subject.perform }
        .to have_enqueued_mail(Event::TourParticipationMailer, :confirmation)
        .with(participation, "event_tour_application_confirmation_applied")
        .and not_change { ActionMailer::Base.deliveries.size }
    end
  end
end
