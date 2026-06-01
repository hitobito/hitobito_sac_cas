# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Participations::MailDispatchesController do
  include ActiveJob::TestHelper

  let(:participation) { Event::Participation.create!(event: event, person: people(:mitglied)) }
  let(:group) { event.groups.first }
  let(:user) { people(:admin) }

  before { sign_in(user) }

  shared_examples "dispatches mail" do |mail_type, mailer, method, *args|
    it "dispatches #{mail_type}" do
      resolved = args.map { |a| (a == :participation) ? participation : a }
      matcher = have_enqueued_mail(mailer, method)
      matcher = matcher.with(*resolved) unless resolved.empty?
      expect do
        post :create,
          params: {group_id: group, event_id: event, participation_id: participation,
                   mail_type: mail_type}
      end.to matcher
    end
  end

  describe "POST #create" do
    context "course" do
      let(:event) do
        Fabricate(:sac_course,
          kind: event_kinds(:ski_course),
          link_survey: "bitte-bitte-umfrage-ausfüllen.ch",
          language: "de")
      end

      it_behaves_like "dispatches mail",
        :event_participation_canceled,
        Event::CourseParticipationMailer,
        :canceled
      it_behaves_like "dispatches mail",
        :event_canceled_no_leader,
        Event::CourseParticipationMailer,
        :event_canceled_no_leader
      it_behaves_like "dispatches mail",
        :event_canceled_minimum_participants,
        Event::CourseParticipationMailer,
        :event_canceled_minimum_participants
      it_behaves_like "dispatches mail",
        :event_canceled_weather,
        Event::CourseParticipationMailer,
        :event_canceled_weather
      it_behaves_like "dispatches mail",
        :event_participation_summon,
        Event::CourseParticipationMailer,
        :summon
      it_behaves_like "dispatches mail",
        :event_participation_reject_rejected,
        Event::CourseParticipationMailer,
        :reject_rejected
      it_behaves_like "dispatches mail",
        :event_participation_reject_applied,
        Event::CourseParticipationMailer,
        :reject_applied
      it_behaves_like "dispatches mail",
        :event_survey,
        Event::CourseParticipationMailer,
        :survey
      it_behaves_like "dispatches mail",
        :event_participant_reminder,
        Event::CourseParticipationMailer,
        :reminder,
        :participation
      it_behaves_like "dispatches mail",
        :course_application_confirmation_assigned,
        Event::CourseParticipationMailer,
        :confirmation, :participation, "course_application_confirmation_assigned"
      it_behaves_like "dispatches mail",
        :course_application_confirmation_unconfirmed,
        Event::CourseParticipationMailer,
        :confirmation, :participation, "course_application_confirmation_unconfirmed"
      it_behaves_like "dispatches mail",
        :course_application_confirmation_applied,
        Event::CourseParticipationMailer,
        :confirmation, :participation, "course_application_confirmation_applied"

      context "with leader role" do
        before { Event::Course::Role::Leader.create!(participation: participation) }

        it_behaves_like "dispatches mail",
          :event_published_notice,
          Event::CourseMailer,
          :published
        it_behaves_like "dispatches mail",
          :event_leader_reminder_next_week,
          Event::CourseParticipationMailer,
          :leader_reminder, :participation, "event_leader_reminder_next_week"
        it_behaves_like "dispatches mail",
          :event_leader_reminder_8_weeks,
          Event::CourseParticipationMailer,
          :leader_reminder, :participation, "event_leader_reminder_8_weeks"
      end
    end

    context "tour" do
      let(:event) { events(:section_tour) }

      before do
        Fabricate(
          "Group::SektionsTourenUndKurse::TourenchefSommer",
          person: user,
          group: groups(:bluemlisalp_touren_und_kurse)
        )
      end

      it_behaves_like "dispatches mail",
        :event_tour_application_confirmation_applied,
        Event::TourParticipationMailer,
        :confirmation, :participation, "event_tour_application_confirmation_applied"
      it_behaves_like "dispatches mail",
        :event_tour_application_confirmation_unconfirmed,
        Event::TourParticipationMailer,
        :confirmation, :participation, "event_tour_application_confirmation_unconfirmed"
      it_behaves_like "dispatches mail",
        :event_tour_application_confirmation_assigned,
        Event::TourParticipationMailer,
        :confirmation, :participation, "event_tour_application_confirmation_assigned"
      it_behaves_like "dispatches mail",
        :event_tour_participation_reject,
        Event::TourParticipationMailer,
        :reject
      it_behaves_like "dispatches mail",
        :event_tour_participation_summon,
        Event::TourParticipationMailer,
        :summon
      it_behaves_like "dispatches mail",
        :event_tour_closing,
        Event::TourParticipationMailer,
        :closing
      it_behaves_like "dispatches mail",
        :event_tour_participation_canceled,
        Event::TourParticipationMailer,
        :canceled
      it_behaves_like "dispatches mail",
        :event_tour_canceled_minimum_participants,
        Event::TourParticipationMailer,
        :canceled_minimum_participants
      it_behaves_like "dispatches mail",
        :event_tour_canceled_no_leader,
        Event::TourParticipationMailer,
        :canceled_no_leader
      it_behaves_like "dispatches mail",
        :event_tour_canceled_weather,
        Event::TourParticipationMailer,
        :canceled_weather
    end
  end
end
