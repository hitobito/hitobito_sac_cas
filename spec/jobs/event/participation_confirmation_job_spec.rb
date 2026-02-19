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
  let(:participation) {
    Fabricate(:event_participation, event: event, participant: person, application: application)
  }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds", "custom_contents.rb")]
  end

  subject { Event::ParticipationConfirmationJob.new(participation) }

  describe "Event sends directly" do
    let(:event) {
      Fabricate(:event, application_opening_at: 5.days.ago, groups: [group],
        applications_cancelable: true)
    }

    it "sends event via coure unconfirmed email" do
      # rubocop:todo Layout/LineLength
      expect(Event::ParticipationMailer).to receive(:confirmation).with(participation).and_call_original
      # rubocop:enable Layout/LineLength
      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
        .and not_have_enqueued_mail(Event::ApplicationConfirmationMailer, :confirmation)
    end
  end

  describe "Event::Course uses Event::ApplicationConfirmationMailer" do
    let(:group) { groups(:root) }

    let(:event) {
      Fabricate(:sac_course, application_opening_at: 5.days.ago, groups: [group],
        applications_cancelable: true)
    }

    before do
      expect(Event::ParticipationMailer).not_to receive(:confirmation)
    end

    it "sends course specific unconfirmed email" do
      expect do
        subject.perform
      end.to have_enqueued_mail(Event::ApplicationConfirmationMailer, :confirmation).with(
        participation, "course_application_confirmation_unconfirmed"
      )
        .and not_change { ActionMailer::Base.deliveries.size }
    end

    it "sends course specific assigned email" do
      participation.update!(state: :assigned)
      expect do
        subject.perform
      end.to have_enqueued_mail(Event::ApplicationConfirmationMailer, :confirmation).with(
        participation, "course_application_confirmation_assigned"
      )
        .and not_change { ActionMailer::Base.deliveries.size }
    end

    it "sends course specific applied email" do
      participation.update!(state: :applied)
      expect do
        subject.perform
      end.to have_enqueued_mail(Event::ApplicationConfirmationMailer, :confirmation).with(
        participation, "course_application_confirmation_applied"
      )
        .and not_change { ActionMailer::Base.deliveries.size }
    end
  end
end
