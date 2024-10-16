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

    def build_role(key, role)
      group = groups(key)
      types = group.role_types.collect { |rt| [rt.to_s.demodulize, rt.sti_name] }.to_h
      participation.person.roles.build(type: types.fetch(role), group: group)
    end

    it "is false when price_subsidized is nil" do
      expect(participation).not_to be_subsidizable
    end

    it "is false when person has no role" do
      expect(participation).not_to be_subsidizable
    end

    [
      [:bluemlisalp_mitglieder, "Mitglied"],
      [:bluemlisalp_neuanmeldungen_nv, "Neuanmeldung"],
      [:bluemlisalp_neuanmeldungen_sektion, "Neuanmeldung"]
    ].each do |group, role|
      it "is true if person has #{role} in #{group}" do
        build_role(group, role)
        expect(participation).to be_subsidizable
      end
    end
  end

  describe "validations" do
    let(:event) { events(:top_course) }

    subject(:participation) { Fabricate(:event_participation, event: event) }

    context "actual_days" do
      it "has to be a positive number" do
        participation.actual_days = -1
        expect(participation).to_not be_valid
        expect(participation.errors.full_messages).to match_array(["Effektive Tage muss grösser oder gleich 0 sein"])

        participation.actual_days = event.total_duration_days + 1
        expect(participation).to_not be_valid
        expect(participation.errors.full_messages).to match_array(["Effektive Tage darf nicht länger als geplante Kursdauer sein."])
      end

      it "can be zero" do
        participation.actual_days = 0
        expect(participation).to be_valid
      end
    end
  end

  describe "canceled" do
    let(:event) { Fabricate(:sac_open_course) }
    let(:participation) { event.participations.create!(person: people(:mitglied)) }

    it "sends a confirmation email" do
      expect { participation.update(state: :canceled, canceled_at: Time.zone.today) }
        .to have_enqueued_mail(Event::ParticipationCanceledMailer, :confirmation).once
    end
  end
end
