# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::EmergencyContactsCleanupJob do
  subject { described_class.new.perform_internal }

  let(:person) do
    Fabricate(:person).tap do |person|
      person.update!(
        emergency_contact_1_name: "Tina #{person.last_name}",
        emergency_contact_1_phone: "+41791234567",
        emergency_contact_2_name: "Xanthippe #{person.last_name}",
        emergency_contact_2_phone: "+41791234568"
      )
    end
  end

  before do
    allow(Settings.event.participations)
      .to receive(:delete_emergency_contacts_after_months)
      .and_return(6)
  end

  def with_dates(event, **dates)
    Event::Date.where(event_id: event.id).update_all(
      start_at: dates.fetch(:start_at, 8.months.ago),
      finish_at: dates.fetch(:finish_at, 7.months.ago)
    )
  end

  def course_with_dates(**dates)
    Fabricate(:sac_course).tap { |course| with_dates(course, **dates) }
  end

  def tour_with_dates(**dates)
    Fabricate(:sac_tour).tap { |tour| with_dates(tour, **dates) }
  end

  def event_with_dates(**dates)
    Fabricate(:event).tap { |event| with_dates(event, **dates) }
  end

  def participate_in(event)
    Fabricate(:event_participation, event: event, participant: person)
  end

  context "after cutoff, with only a participation in a past" do
    context "course" do
      it "clears all emergency contact attributes" do
        participate_in(course_with_dates)

        expect { subject }.to change { person.reload.emergency_contact_1_name }.to(nil)
          .and change { person.reload.emergency_contact_1_phone }.to(nil)
          .and change { person.reload.emergency_contact_2_name }.to(nil)
          .and change { person.reload.emergency_contact_2_phone }.to(nil)
      end
    end

    context "tour" do
      it "clears all emergency contact attributes" do
        participate_in(tour_with_dates)

        expect { subject }.to change { person.reload.emergency_contact_1_name }.to(nil)
          .and change { person.reload.emergency_contact_1_phone }.to(nil)
          .and change { person.reload.emergency_contact_2_name }.to(nil)
          .and change { person.reload.emergency_contact_2_phone }.to(nil)
      end
    end

    context "event" do
      it "does not change the contact attributes" do
        participate_in(event_with_dates)

        expect { subject }.not_to change { person.reload.emergency_contact_1_name }
      end
    end
  end

  context "inside cutoff, with only a participation in a past" do
    context "course" do
      it "keeps the emergency contacts" do
        participate_in(course_with_dates(start_at: 5.months.ago, finish_at: 2.months.ago))

        expect { subject }.not_to change { person.reload.emergency_contact_1_name }
      end
    end
  end

  context "with a participation in an upcoming" do
    context "one-day course" do
      it "keeps the emergency contacts" do
        participate_in(course_with_dates) # in the past
        participate_in(course_with_dates(start_at: 1.week.from_now,
          finish_at: 2.weeks.from_now))

        expect { subject }.not_to change { person.reload.emergency_contact_1_name }
      end
    end

    context "multi date course" do
      it "keeps the emergency contacts" do
        participate_in(course_with_dates)
        course = course_with_dates
        Event::Date.create!(event: course, start_at: 1.month.from_now)
        participate_in(course)

        expect { subject }.not_to change { person.reload.emergency_contact_1_name }
      end
    end
  end

  context "without setting configured, the job" do
    before do
      allow(Settings.event.participations)
        .to receive(:delete_emergency_contacts_after_months)
        .and_return(nil)
    end

    it "does nothing" do
      participate_in(course_with_dates)

      expect { subject }.not_to change { person.reload.emergency_contact_1_name }
    end
  end
end
