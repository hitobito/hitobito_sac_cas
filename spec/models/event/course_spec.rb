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
        :link_external_site,
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

    it "season is configured as an i18n_enum" do
      expect(described_class.season_labels).to eq [
        [:summer, "Sommer"],
        [:winter, "Winter"]
      ].to_h
    end

    it "canceled_reason is configured as an i18n_enum" do
      expect(described_class.canceled_reason_labels).to eq [
        [:minimum_participants, "Minimale Teilnehmerzahl nicht erreicht"],
        [:no_leader, "Ausfall Kursleitung"],
        [:weather, "Wetterrisiko"]
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
    let(:course) { events(:application_closed) }

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

    describe "application_paused" do
      before { course.update_columns(state: "application_paused") }

      it "closes course if closing date changes to past" do
        course.update!(application_closing_at: Time.zone.yesterday)
        expect(course.state).to eq "application_closed"
      end

      it "does not change state course if closing date changes to today" do
        course.update!(application_closing_at: Time.zone.today)
        expect(course.state).to eq "application_paused"
      end

      it "does not change state course if closing date changes to future" do
        course.update!(application_closing_at: Time.zone.tomorrow)
        expect(course.state).to eq "application_paused"
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

    describe "assignment_closed state" do
      before { course.update_columns(state: "assignment_closed") }

      it "does not change state if closing date changes to past" do
        course.update_columns(application_closing_at: Time.zone.yesterday)
        course.update!(state: "application_closed")

        expect(course.state).to eq "application_closed"
      end

      it "does change state if closing date changes to today" do
        course.update_columns(application_closing_at: Time.zone.today)
        course.update!(state: "application_closed")

        expect(course.state).to eq "application_open"
      end

      it "opens course for application state if closing date changes to future" do
        course.update_columns(application_closing_at: Time.zone.tomorrow)
        course.update!(state: "application_closed")

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

      context "for someone else" do
        subject(:state) { course.default_participation_state(participation, true) }

        it "returns assigned if places are available" do
          expect(state).to eq "assigned"
        end

        it "returns applied if course has no places available" do
          course.participant_count = 2
          expect(state).to eq "applied"
        end
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

      context "for someone else" do
        subject(:state) { course.default_participation_state(participation, true) }

        it "returns assigned if places are available" do
          expect(state).to eq "assigned"
        end

        it "returns applied if course has no places available" do
          course.participant_count = 2
          expect(state).to eq "applied"
        end
      end
    end
  end

  describe "#available_states" do
    let(:course) { events(:application_closed) }

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
    let(:course) { events(:application_closed) }

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
    let(:course) { events(:application_closed) }

    # set up participants who have been rejected
    let(:application) { Fabricate(:event_application, priority_1: course, rejected: true) }
    let!(:applied_participation) { Fabricate(:event_participation, event: course, application:, state: :applied) }
    let!(:rejected_participation) { Fabricate(:event_participation, event: course, application:, state: :rejected) }
    let!(:unconfirmed_participation) { Fabricate(:event_participation, event: course, application:, state: :unconfirmed) }

    it "queues job to notify rejected and applied participants" do
      expect { course.update!(state: :assignment_closed) }
        .to have_enqueued_mail(Event::ParticipationMailer, :reject_applied).once
        .and have_enqueued_mail(Event::ParticipationMailer, :reject_rejected).once
        .and have_enqueued_mail(Event::ParticipationMailer, :reject_unconfirmed).once
    end
  end

  describe "when state changes to ready" do
    let(:course) { events(:application_closed).tap { |c| c.update!(state: :assignment_closed) } }
    let(:application) { Fabricate(:event_application, priority_1: course, rejected: true) }
    let(:leader) { @participations.first }
    let(:participant) { @participations.second }

    before { course.dates.build(start_at: Time.zone.local(2025, 5, 11)) }

    before do
      @participations = course.participations.create!([
        {person: people(:admin)},
        {person: people(:mitglied), state: :assigned, price: 10, price_category: "price_regular", application: application},
        {person: people(:familienmitglied), state: :assigned, price: 10, price_category: "price_regular"}
      ])
      @participations.first.roles.create!(type: Event::Course::Role::Leader)
      @participations.second.roles.create!(type: Event::Course::Role::Participant)
      @participations.third.roles.create!(type: Event::Course::Role::Participant)
    end

    context "from assignment_closed" do
      it "updates assigned participants to summoned" do
        expect { course.update!(state: :ready) }
          .to change { participant.reload.state }.to(eq("summoned"))
          .and have_enqueued_mail(Event::ParticipationMailer, :summon).twice
          .and change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count).by(2)
        expect(leader.reload.state).to eq("assigned")
      end

      it "doesn't enqueue a job if there already is an external invoice" do
        ExternalInvoice::CourseParticipation.create!(person_id: participant.person_id, link: participant)

        expect { course.update!(state: :ready) }.to change(
          Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count
        ).by(1)
      end

      it "doesn't enqueue a job if participation price is nil" do
        participant.update_attribute(:price, nil)

        expect { course.update!(state: :ready) }.to change(Delayed::Job, :count).by(1)
      end
    end

    context "from closed" do
      it "does not update assigned participants to summoned" do
        course.update_attribute(:state, :closed)

        expect { course.update!(state: :ready) }
          .to_not change { participant.reload.state }
      end
    end
  end

  describe "when state changes to application_open" do
    let(:course) { Fabricate(:sac_open_course, contact_id: people(:admin).id) }

    before { Group.root.update!(course_admin_email: "admin@example.com") }

    context "from created" do
      before do
        course.participations.create!([{person: people(:admin)}, {person: people(:mitglied)}, {person: people(:familienmitglied)}])
        course.update!(state: :created)
      end

      context "with course leaders" do
        before do
          course.participations.first.roles.create!(type: Event::Course::Role::Leader)
          course.participations.second.roles.create!(type: Event::Course::Role::AssistantLeader)
          course.participations.third.roles.create!(type: Event::Course::Role::Participant)
        end

        it "sends an email to the course admin and leader" do
          expect { course.update!(state: :application_open) }
            .to have_enqueued_mail(Event::PublishedMailer, :notice).twice
        end

        it "skips email if told to do so" do
          course.skip_emails = true
          expect { course.update!(state: :application_open) }.not_to have_enqueued_mail
        end
      end

      context "with course assistant leader" do
        before { course.participations.first.roles.create!(type: Event::Course::Role::AssistantLeader) }

        it "sends an email to the course admin and assistant leader" do
          expect { course.update!(state: :application_open) }
            .to have_enqueued_mail(Event::PublishedMailer, :notice).once
        end
      end

      context "without course leaders" do
        it "doesn't queue a job to send an email" do
          expect { course.update!(state: :application_open) }
            .not_to have_enqueued_mail(Event::PublishedMailer)
        end
      end
    end

    context "from anything else" do
      before { course.update!(state: :application_paused) }

      it "doesn't send an email" do
        expect { course.update!(state: :application_open) }
          .not_to have_enqueued_mail(Event::PublishedMailer)
      end
    end
  end

  describe "when state changes to application_paused" do
    let(:course) { Fabricate(:sac_open_course, language: "fr") }

    context "with course admin" do
      before { Group.root.update!(course_admin_email: "admin@example.com") }

      it "sends an email to the course admin" do
        expect { course.update!(state: :application_paused) }
          .to have_enqueued_mail(Event::ApplicationPausedMailer, :notice).once
      end
    end

    context "without course admin" do
      before { Group.root.update!(course_admin_email: nil) }

      it "doesn't queue the job to send an email" do
        expect { course.update!(state: :application_paused) }
          .not_to have_enqueued_mail(Event::ApplicationPausedMailer, :notice)
      end
    end
  end

  describe "when state changes to application_closed" do
    let(:course) do
      Fabricate(:sac_open_course,
        state: :assignment_closed,
        application_opening_at: 1.month.ago,
        application_closing_at: 1.week.ago)
    end

    context "with course admin" do
      before { Group.root.update!(course_admin_email: "admin@example.com") }

      it "sends an email to the course admin" do
        expect { course.update!(state: :application_closed) }
          .to have_enqueued_mail(Event::ApplicationClosedMailer, :notice).once
      end
    end

    context "without course admin" do
      before { Group.root.update!(course_admin_email: nil) }

      it "doesn't queue the job to send an email" do
        expect { course.update!(state: :application_closed) }
          .not_to have_enqueued_mail(Event::ApplicationClosedMailer)
      end
    end
  end

  describe "when state changes to canceled" do
    let(:course) { Fabricate(:sac_open_course, state: :assignment_closed) }

    context "with participants" do
      before do
        course.inform_participants = "1"
        course.participations.create!([
          {person: people(:admin), state: :assigned, active: true, roles: [Event::Course::Role::Leader.new]},
          {person: people(:mitglied), state: :assigned, active: true, roles: [Event::Course::Role::Participant.new]},
          {person: people(:familienmitglied), state: :rejected, active: false, roles: [Event::Course::Role::Participant.new]}
        ])
      end

      it "changes participation states to canceled" do
        expect(course.participations.count).to eq(3)
        course.update!(state: :canceled, canceled_reason: :minimum_participants)
        participations = course.participations.order(:state, :previous_state)
        expect(participations.map(&:state)).to eq(%w[annulled annulled assigned])
        expect(participations.map(&:previous_state)).to eq(["assigned", "rejected", nil])
      end

      it "sends an email to all participants if canceled because of minimum participants" do
        expect { course.update!(state: :canceled, canceled_reason: :minimum_participants) }
          .to have_enqueued_mail(Event::CanceledMailer, :minimum_participants).twice
      end

      it "sends an email to all participants if canceled because of no_leader" do
        expect { course.update!(state: :canceled, canceled_reason: :no_leader) }
          .to have_enqueued_mail(Event::CanceledMailer, :no_leader).twice
      end

      it "sends an email to all participants if canceled because of weather" do
        expect { course.update!(state: :canceled, canceled_reason: :weather) }
          .to have_enqueued_mail(Event::CanceledMailer, :weather).twice
      end

      it "does not sends an email when participant is canceled" do
        course.participations.update_all(state: :canceled)
        expect { course.update!(state: :canceled, canceled_reason: :weather) }
          .not_to have_enqueued_mail
      end

      it "does not sends an emails when inform_participants=0" do
        course.inform_participants = 0
        expect { course.update!(state: :canceled, canceled_reason: :weather) }
          .not_to have_enqueued_mail
      end
    end

    context "without participants" do
      it "doesnt send an email" do
        expect { course.update!(state: :canceled) }.not_to have_enqueued_mail(Event::CanceledMailer)
      end
    end

    context "invoice" do
      before do
        p1, p2 = course.participations.create!([{person: people(:admin)}, {person: people(:mitglied)}])
        ExternalInvoice::CourseParticipation.create!(person_id: p1.person_id, link: p1)
        ExternalInvoice::CourseParticipation.create!(person_id: p2.person_id, link: p2)
      end

      it "queues job to cancel invoices for all participants" do
        expect do
          course.update!(state: :canceled)
        end.to change { Delayed::Job.where("handler like '%CancelInvoiceJob%'").count }.by(2)
      end
    end
  end

  describe "when state changes to closed" do
    let(:course) { Fabricate(:sac_open_course, state: :ready) }

    before do
      _p1, p2, p3, p4 = course.participations.create!([
        {person: people(:admin), roles: [Event::Course::Role::Leader.new], price: 0},
        {person: people(:mitglied), state: :absent, price: 42, price_category: "price_regular"},
        {person: people(:familienmitglied), state: :attended, price: 42, price_category: "price_regular"},
        {person: people(:familienmitglied2), state: :absent, price: 42, price_category: "price_regular"}
      ])
      ExternalInvoice::CourseParticipation.create!(person_id: p2.person_id, link: p2, total: p2.price)
      ExternalInvoice::CourseParticipation.create!(person_id: p3.person_id, link: p3, total: p3.price)
      ExternalInvoice::CourseAnnulation.create!(person_id: p4.person_id, link: p4, total: p4.price) # annulation invoice alredy exists
    end

    it "does not set participation state for assigned participations" do
      expect { course.update!(state: :closed) }
        .not_to change { course.participations.order(:state).pluck(:state) }
    end

    it "sets participation state to attended for summoned participations" do
      course.participations.update_all(state: :summoned)
      course.update!(state: :closed)

      expect(course.participations.order(:state).pluck(:state)).to eq(["attended", "attended", "attended", "attended"])
    end

    it "queues job for absent invoices for absent participants" do
      expect do
        course.update!(state: :closed)
      end.to change { Delayed::Job.where("handler like '%CreateCourseInvoiceJob%'").count }.by(1).and \
        change { Delayed::Job.where("handler like '%CancelInvoiceJob%'").count }.by(1)
    end
  end

  describe "when state changes from closed" do
    let(:course) { Fabricate(:sac_open_course, state: :closed) }

    before do
      course.participations.create!([
        {person: people(:admin), roles: [Event::Course::Role::Leader.new], state: :summoned},
        {person: people(:mitglied), state: :summoned}
      ])
    end

    it "does nothing" do
      expect { course.update!(state: :ready) }
        .not_to change { course.participations.order(:state).pluck(:state) }
    end
  end

  describe "#total_event_days" do
    subject(:course) { Fabricate.build(:sac_course, start_point_of_time: :day) }

    it "returns 0 days when there are no dates" do
      expect(course.total_event_days).to eq(0)
    end

    describe "single date with only start_at" do
      it "returns 1 for date" do
        course.dates.build(start_at: Time.zone.parse("2024-01-01"))
        expect(course.total_event_days).to eq(1)
      end

      it "returns 1 for datetime" do
        course.dates.build(start_at: Time.zone.parse("2024-01-01 11:00"))
        expect(course.total_event_days).to eq(1)
      end

      it "subtracts 0.5 when even starts in the evening" do
        course.start_point_of_time = :evening
        course.dates.build(start_at: Time.zone.parse("2024-01-01 20:00"))
        expect(course.total_event_days).to eq(0.5)
      end
    end

    describe "single date with start and finish at" do
      it "returns 1 if they are on the sem date" do
        course.dates.build(start_at: Time.zone.parse("2024-01-01 10:00"), finish_at: Time.zone.parse("2024-01-01 23:00"))
        expect(course.total_event_days).to eq(1)
      end

      it "returns still 1 if they they finish in the morning" do
        course.dates.build(start_at: Time.zone.parse("2024-01-01 10:00"), finish_at: Time.zone.parse("2024-01-01 12:00"))
        expect(course.total_event_days).to eq(1)
      end

      it "returns 0.5 if event starts in the evening" do
        course.start_point_of_time = :evening
        course.dates.build(start_at: Time.zone.parse("2024-01-01 10:00"), finish_at: Time.zone.parse("2024-01-01 12:00"))
        expect(course.total_event_days).to eq(0.5)
      end

      it "counts days ignoring start and end times on each day" do
        course.dates.build(start_at: Time.zone.parse("2024-01-01 10:00"), finish_at: Time.zone.parse("2024-01-03 10:00"))
        expect(course.total_event_days).to eq(3)
      end

      it "still subtracts 0.5 if starting in the evening" do
        course.start_point_of_time = :evening
        course.dates.build(start_at: Time.zone.parse("2024-01-01 10:00"), finish_at: Time.zone.parse("2024-01-03 10:00"))
        expect(course.total_event_days).to eq(2.5)
      end
    end

    describe "multiple dates" do
      it "returns the total days across all dates" do
        course.dates.build(start_at: Time.zone.parse("2024-01-01 10:00"), finish_at: Time.zone.parse("2024-01-02 08:00"))
        course.dates.build(start_at: Time.zone.parse("2024-01-05 10:00"), finish_at: Time.zone.parse("2024-01-07 08:00"))
        expect(course.total_event_days).to eq(5)
      end
      it "still subtracts 0.5 if starting in the evening" do
        course.start_point_of_time = :evening
        course.dates.build(start_at: Time.zone.parse("2024-01-01 10:00"), finish_at: Time.zone.parse("2024-01-02 08:00"))
        course.dates.build(start_at: Time.zone.parse("2024-01-05 10:00"), finish_at: Time.zone.parse("2024-01-07 08:00"))
        expect(course.total_event_days).to eq(4.5)
      end
    end
  end
end
