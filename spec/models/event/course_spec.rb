# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Course do
  include ActiveJob::TestHelper

  describe "::validations" do
    subject(:course) do
      course = Fabricate.build(:sac_course)
      course.dates.build(start_at: Time.zone.local(2012, 5, 11))
      course
    end

    it "validates presence of number" do
      course.number = nil
      expect(course).not_to be_valid
      expect(course.errors[:number]).to eq ["muss ausgefüllt werden"]
    end

    it "validates uniqueness of number" do
      events(:top_course).update_columns(number: 1)
      course.number = 1
      expect(course).not_to be_valid
      expect(course.errors[:number]).to eq ["ist bereits vergeben"]
    end

    [:description, :application_opening_at, :application_closing_at, :contact_id,
      :location, :language, :cost_center_id, :cost_unit_id, :season, :start_point_of_time,
      :price_member, :price_regular].each do |attribute|
      describe "validates presence of #{attribute}" do
        it "validates presence of #{attribute} in state ready" do
          allow(course).to receive(:state).and_return(:ready)
          expect(course).not_to be_valid
          expect(course.errors[attribute]).to eq ["muss ausgefüllt werden"]
        end

        it "does not validate presence of #{attribute} in state created" do
          expect(course.state).to eq("created")
          expect(course).to be_valid
        end
      end
    end
  end

  describe "#used_attributes" do
    it "has expected additions" do
      expect(described_class.used_attributes).to include(
        :accommodation,
        :annual,
        :cost_center_id,
        :cost_unit_id,
        :language,
        :link_leaders,
        :link_participants,
        :link_survey,
        :minimum_age,
        :reserve_accommodation, :season,
        :start_point_of_time
      )
    end

    it "has expected removals" do
      expect(described_class.used_attributes).not_to include(:cost)
    end
  end

  describe "#i18n_enums" do
    it "language is configured as an i18n_enum" do
      expect(described_class.language_labels).to eq [
        [:de_fr, "Deutsch/Französisch"],
        [:de, "Deutsch"],
        [:fr, "Französisch"],
        [:it, "Italienisch"]
      ].to_h
    end

    it "accommodation is configured as an i18n_enum" do
      expect(described_class.accommodation_labels).to eq [
        [:bivouac, "Übernachtung im Freien/Biwak"],
        [:hut, "Hütte"],
        [:no_overnight, "ohne Übernachtung"],
        [:pension, "Pension/Berggasthaus"],
        [:pension_or_hut, "Pension/Berggasthaus oder Hütte"]
      ].to_h
    end

    it "start_point_of_time is configured as an i18n_enum" do
      expect(described_class.start_point_of_time_labels).to eq [
        [:day, "Tag"],
        [:evening, "Abend"]
      ].to_h
    end

    it "season is configure as an i18n_enum" do
      expect(described_class.season_labels).to eq [
        [:summer, "Sommer"],
        [:winter, "Winter"]
      ].to_h
    end
  end

  describe "#minimum_age" do
    subject(:course) { described_class.new }

    it "is read from course not kind" do
      expect(course.minimum_age).to be_nil
      course.kind = Event::Kind.new(minimum_age: 1)
      expect(course.minimum_age).to be_nil
      course.minimum_age = 2
      expect(course.minimum_age).to eq 2
    end
  end

  describe "#level" do
    subject(:course) { Fabricate(:sac_course) }

    it "returns value from kind" do
      expect(course.level).to eq event_levels(:ek)
    end

    it "does not fail when kind level is nil" do
      course.kind.level = nil
      expect(course.level).to be_nil
    end
  end

  describe "application_closing_at dependent state transitions" do
    let(:course) { events(:closed) }

    describe "application_open" do
      before { course.update_columns(state: "application_open") }

      it "closes course if closing date changes to past" do
        course.update!(application_closing_at: Time.zone.yesterday)
        expect(course.state).to eq "application_closed"
      end

      it "does not change state course if closing date changes to today" do
        course.update!(application_closing_at: Time.zone.today)
        expect(course.state).to eq "application_open"
      end

      it "does not change state course if closing date changes to future" do
        course.update!(application_closing_at: Time.zone.tomorrow)
        expect(course.state).to eq "application_open"
      end
    end

    # does not work as expected, validations are build using states defined in youth wagon
    describe "application_paused" do
      before { course.update_columns(state: "application_open") }

      it "closes course if closing date changes to past" do
        course.update!(application_closing_at: Time.zone.yesterday)
        expect(course.state).to eq "application_closed"
      end

      it "does not change state course if closing date changes to today" do
        course.update!(application_closing_at: Time.zone.today)
        expect(course.state).to eq "application_open"
      end

      it "does not change state course if closing date changes to future" do
        course.update!(application_closing_at: Time.zone.tomorrow)
        expect(course.state).to eq "application_open"
      end
    end

    describe "application_closed state" do
      before { course.update_columns(state: "application_closed") }

      it "does not change state if closing date changes to past" do
        course.update!(application_closing_at: Time.zone.yesterday)

        expect(course.state).to eq "application_closed"
      end

      it "does change state if closing date changes to today" do
        course.update!(application_closing_at: Time.zone.today)
        expect(course.state).to eq "application_open"
      end

      it "opens course for application state if closing date changes to future" do
        course.update!(application_closing_at: Time.zone.tomorrow)
        expect(course.state).to eq "application_open"
      end
    end
  end

  describe "#refresh_participant_counts!" do
    let(:course) { events(:top_course) }
    let(:admin) { people(:admin) }

    it "updates unconfirmed_count" do
      Fabricate(:event_participation, event: course)
      Fabricate(:event_participation, event: course, state: :unconfirmed)
      unconfirmed = Fabricate(:event_participation, event: course, state: :unconfirmed)
      expect do
        course.refresh_participant_counts!
      end.to change { course.reload.unconfirmed_count }.from(0).to(2)

      unconfirmed.update!(state: :assigned)
      expect do
        course.refresh_participant_counts!
      end.to change { course.reload.unconfirmed_count }.from(2).to(1)
    end
  end

  describe "#default_participation_state" do
    let(:course) { Fabricate.build(:sac_course, participant_count: 1, maximum_participants: 2) }
    let(:application) { Fabricate.build(:event_application) }
    let(:participation) { Fabricate.build(:event_participation, event: course, application: application, state: "assigned") }

    subject(:state) { course.default_participation_state(participation) }

    context "without automatic_assignment" do
      before { course.automatic_assignment = false }

      it "returns unconfirmed if places are available" do
        expect(state).to eq "unconfirmed"
      end

      it "returns applied if course has no places available" do
        course.participant_count = 2
        expect(state).to eq "applied"
      end
    end

    context "with automatic_assignment" do
      before { course.automatic_assignment = true }

      it "returns applied if places are available" do
        expect(state).to eq "applied"
      end

      it "returns applied if course has no places available" do
        course.participant_count = 2
        expect(state).to eq "applied"
      end
    end
  end

  describe "#available_states" do
    let(:course) { events(:closed) }

    it "lists available states for state :created" do
      expect(course).to receive(:state).and_return(:created)
      expect(course.available_states).to eq([:application_open])
    end

    it "lists available states for state :application_open" do
      expect(course).to receive(:state).and_return(:application_open)
      expect(course.available_states).to eq([:application_paused, :created, :canceled])
    end

    it "lists available states for state :application_paused" do
      expect(course).to receive(:state).and_return(:application_paused)
      expect(course.available_states).to eq([:application_open])
    end

    it "lists available states for state :application_closed" do
      expect(course).to receive(:state).and_return(:application_closed)
      expect(course.available_states).to eq([:assignment_closed, :canceled])
    end

    it "lists available states for state :assignment_closed" do
      expect(course).to receive(:state).and_return(:assignment_closed)
      expect(course.available_states).to eq([:ready, :application_closed, :canceled])
    end

    it "lists available states for state :ready" do
      expect(course).to receive(:state).and_return(:ready)
      expect(course.available_states).to eq([:closed, :assignment_closed, :canceled])
    end

    it "lists available states for state :canceled" do
      expect(course).to receive(:state).and_return(:canceled)
      expect(course.available_states).to eq([:application_open])
    end

    it "lists available states for state :closed" do
      expect(course).to receive(:state).and_return(:closed)
      expect(course.available_states).to eq([:ready])
    end
  end

  describe "state change validation" do
    let(:course) { events(:closed) }

    it "state cannot be changed from closed to created" do
      expect(course).to be_valid
      course.state = :created

      expect(course).not_to be_valid
      expect(course.errors.attribute_names).to include(:state)
      expect(course.errors[:state].first).to eq("State cannot be changed from application_closed to created")
    end

    it "state can be changed from application_closed to canceled" do
      expect(course).to be_valid
      course.state = :canceled

      expect(course).to be_valid
    end
  end

  describe "when state changes to assignment_closed" do
    let(:course) { events(:closed) }

    # set up participants who have been rejected
    let(:application) { Fabricate(:event_application, priority_1: course, rejected: true) }
    let!(:applied_participation) { Fabricate(:event_participation, event: course, application:, state: :applied) }
    let!(:rejected_participation) { Fabricate(:event_participation, event: course, application:, state: :rejected) }

    it "queues job to notify rejected and applied participants" do
      expect { course.update!(state: :assignment_closed) }
        .to have_enqueued_mail(Event::ParticipationMailer, :reject_applied).once
        .and have_enqueued_mail(Event::ParticipationMailer, :reject_rejected).once
    end
  end

  describe "when state changes to ready" do
    let(:course) { events(:assignment_closed) }

    # set up participants who have been assigned
    let(:application) { Fabricate(:event_application, priority_1: course, rejected: false) }
    let!(:assigned_participation) { Fabricate(:event_participation, event: course, application:, state: :assigned) }

    context "from assignment_closed" do
      it "updates assigned participants to summoned" do
        course.dates.build(start_at: Time.zone.local(2025, 5, 11))

        expected_participation = assigned_participation.dup
        expected_participation.state = "assigned"
        expect { course.update!(state: :ready) }
          .to change { course.participations.first.state }.to(eq("summoned"))
          .and have_enqueued_mail(Event::ParticipationMailer, :summon).once
      end
    end

    context "from closed" do
      it "does not update assigned participants to summoned" do
        course.dates.build(start_at: Time.zone.local(2025, 5, 11))
        course.update_attribute(:state, :closed)

        expect { course.update!(state: :ready) }
          .to_not change { course.participations.first.state }
      end
    end
  end

  describe "when state changes to application_open" do
    let(:course) { Fabricate(:sac_open_course, contact_id: people(:admin).id) }

    before { course.groups.first.update!(course_admin_email: "admin@example.com") }

    context "from created" do
      before do
        course.participations.create!([{person: people(:admin)}, {person: people(:mitglied)}])
        course.update!(state: :created)
      end

      context "with course leaders" do
        before do
          course.participations.first.roles.create!(type: Event::Role::Leader)
          course.participations.last.roles.create!(type: Event::Role::AssistantLeader)
        end

        it "sends an email to the course admin and leader" do
          expect { course.update!(state: :application_open) }
            .to have_enqueued_mail(Event::PublishedMailer, :notice).twice
        end
      end

      context "with course assistant leader" do
        before { course.participations.first.roles.create!(type: Event::Role::AssistantLeader) }

        it "sends an email to the course admin and assistant leader" do
          expect { course.update!(state: :application_open) }
            .to have_enqueued_mail(Event::PublishedMailer, :notice).once
        end
      end

      context "without course leaders" do
        it "doesnt queue a job to send an email" do
          expect { course.update!(state: :application_open) }
            .not_to have_enqueued_mail(Event::PublishedMailer)
        end
      end
    end

    context "from anything else" do
      before { course.update!(state: :application_paused) }

      it "doesnt send an email" do
        expect { course.update!(state: :application_open) }
          .not_to have_enqueued_mail(Event::PublishedMailer)
      end
    end
  end

  describe "when state changes to application_paused" do
    let(:course) { Fabricate(:sac_open_course, language: "fr") }

    context "with course admin" do
      before { course.groups.first.update!(course_admin_email: "admin@example.com") }

      it "sends an email to the course admin" do
        expect { course.update!(state: :application_paused) }
          .to have_enqueued_mail(Event::ApplicationPausedMailer, :notice).once
      end
    end

    context "without course admin" do
      before { course.groups.first.update!(course_admin_email: nil) }

      it "doesnt queue the job to send an email" do
        expect { course.update!(state: :application_paused) }
          .not_to have_enqueued_mail(Event::ApplicationPausedMailer, :notice)
      end
    end
  end

  describe "when state changes to application_closed" do
    let(:course) { Fabricate(:sac_open_course).tap { |c| c.update_attribute(:state, :assignment_closed) } }

    context "with course admin" do
      before { course.groups.first.update!(course_admin_email: "admin@example.com") }

      it "sends an email to the course admin" do
        expect { course.update!(state: :application_closed) }
          .to have_enqueued_mail(Event::ApplicationClosedMailer, :notice).once
      end
    end

    context "without course admin" do
      before { course.groups.first.update!(course_admin_email: nil) }

      it "doesnt queue the job to send an email" do
        expect { course.update!(state: :application_closed) }
          .not_to have_enqueued_mail(Event::ApplicationClosedMailer)
      end
    end
  end

  describe "when state changes to canceled" do
    let(:course) { Fabricate(:sac_open_course, language: "de") }

    before do
      course.participations.create!([{person: people(:admin)}, {person: people(:mitglied)}])
      ExternalInvoice::Course.create!(person_id: course.participations.first.person_id, link: course)
      ExternalInvoice::Course.create!(person_id: course.participations.second.person_id, link: course)
    end

    it "queues job to cancel invoices for all participants" do
      expect do
        course.update!(state: :canceled)
      end.to change { Delayed::Job.where("handler like '%CancelInvoiceJob%'").count }.by(2)
    end
  end
end
