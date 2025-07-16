# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Participation do
  include ActiveJob::TestHelper

  describe "::callbacks" do
    subject(:participation) { Fabricate(:event_participation, event: events(:top_course)) }

    [
      {state: :canceled, canceled_at: Time.zone.today},
      {state: :annulled}
    ].each do |attrs|
      it "sets previous state when updating to #{attrs[:state]}" do
        expect do
          participation.update!(attrs)
        end.to change { participation.reload.previous_state }.from(nil).to("assigned")
      end
    end
  end

  describe "#participant_cancelable?" do
    let(:course) do
      Fabricate.build(:sac_course).tap { |e| e.dates.build(start_at: 10.days.from_now) }
    end

    subject(:participation) { Fabricate.build(:event_participation, event: course) }

    it "may not be canceled by participant if applications are not cancelable" do
      course.applications_cancelable = false
      expect(participation).not_to be_participant_cancelable
    end

    it "may not be canceled by participant if course is in annulled state" do
      course.applications_cancelable = true
      course.state = "annulled"
      expect(participation).not_to be_participant_cancelable
    end

    it "may not be canceled by participant if course starts today" do
      course.applications_cancelable = true
      course.state = "application_open"
      course.dates.first.start_at = Time.zone.now
      expect(participation).not_to be_participant_cancelable
    end

    it "may not be canceled by participant if course started in the past" do
      course.applications_cancelable = true
      course.state = "application_open"
      course.dates.first.start_at = 1.day.ago
      expect(participation).not_to be_participant_cancelable
    end

    it "may not be canceled by participant if any date is in the past" do
      course.applications_cancelable = true
      course.state = "application_open"
      course.dates.build.start_at = 1.day.from_now
      course.dates.build.start_at = 1.day.ago
      expect(participation).not_to be_participant_cancelable
    end

    it "may be canceled otherwise" do
      course.applications_cancelable = true
      course.state = "application_open"
      course.dates.first.start_at = 1.day.from_now
      expect(participation).to be_participant_cancelable
    end
  end

  describe "#subsidizable?" do
    let(:course) { Fabricate.build(:sac_course, applications_cancelable: true, price_subsidized: 10) }

    subject(:participation) { Fabricate.build(:event_participation, event: course) }

    it "is false when price_subsidized is nil" do
      expect(participation).not_to be_subsidizable
    end

    it "is false when person has no role" do
      expect(participation).not_to be_subsidizable
    end

    it "is true if person is member" do
      participation.person = people(:mitglied)
      expect(participation).to be_subsidizable
    end
  end

  describe "validations" do
    let(:event) { events(:top_course) }

    subject(:participation) { Fabricate.build(:event_participation, event: event) }

    context "actual_days" do
      it "has to be a positive number" do
        participation.actual_days = -1
        expect(participation).to_not be_valid
        expect(participation.errors.full_messages).to match_array(["Effektive Tage muss grösser oder gleich 0 sein"])
      end

      it "must be not greater than event total_duration_days" do
        participation.actual_days = event.total_duration_days + 1
        expect(participation).to_not be_valid
        expect(participation.errors.full_messages).to match_array(["Effektive Tage darf nicht länger als geplante Kursdauer sein."])
      end

      it "is not validated if actual_days did not change" do
        participation.save!
        participation.update_column(:actual_days, event.total_duration_days + 1)
        participation.state = "summoned"
        expect(participation).to be_valid
      end

      it "can be zero" do
        participation.actual_days = 0
        expect(participation).to be_valid
      end

      it "is rounded to 0.5" do
        participation.actual_days = 1.7
        expect(participation).to be_valid
        expect(participation.actual_days).to eq(1.5)
      end

      it "is initialized to training days for participants" do
        event.training_days = 6
        participation.roles.build(type: Event::Course::Role::Participant)
        expect(participation).to be_valid
        expect(participation.actual_days).to eq(6)
      end

      it "is not initialized for leaders" do
        event.training_days = 6
        participation.roles.build(type: Event::Course::Role::Leader)
        expect(participation).to be_valid
        expect(participation.actual_days).to be_nil
      end
    end
  end
end
