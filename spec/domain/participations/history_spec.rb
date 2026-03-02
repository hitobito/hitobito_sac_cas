# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Participations::History do
  let(:admin) { people(:admin) }
  let(:history) { Participations::History.new(admin) }

  describe "#recent_trainings" do
    it "lists a mix of external trainings and course participations ordered by finish_at and respects the limit" do
      first = create_external_training(start_at: 10.days.ago, finish_at: 5.days.ago)
      second = create_course_participation(start_at: 13.days.ago, finish_at: 10.days.ago)
      third = create_external_training(start_at: 15.days.ago, finish_at: 12.days.ago)
      fourth = create_course_participation(start_at: 30.days.ago, finish_at: 15.days.ago)
      fifth = create_course_participation(start_at: 30.days.ago, finish_at: 20.days.ago)

      expected = [first, second, third, fourth, fifth].map { to_history_row(_1) }
      expect(history.recent_trainings).to eq(expected)

      limit_expected = expected.take(3)
      expect(history.recent_trainings(limit: 3)).to eq(limit_expected)
    end

    it "only lists past course participations" do
      past = create_course_participation(start_at: 10.days.ago, finish_at: 2.days.ago)
      create_course_participation(start_at: 10.days.ago, finish_at: nil)
      create_course_participation(start_at: 10.days.ago, finish_at: 2.days.from_now)
      create_course_participation(start_at: 30.days.ago, finish_at: 20.days.ago).tap do |participation|
        participation.event.dates += [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.from_now)]
        participation.save!
      end

      expect(history.recent_trainings).to match_array([to_history_row(past)])
    end

    it "only lists course participations with active participation state" do
      attended = create_course_participation(state: :attended, start_at: 10.days.ago, finish_at: 2.days.ago)
      assigned = create_course_participation(state: :assigned, start_at: 10.days.ago, finish_at: 2.days.ago)
      create_course_participation(state: :canceled, canceled_at: 20.days.ago, start_at: 10.days.ago,
        finish_at: 2.days.ago)
      create_course_participation(state: :absent, canceled_at: 20.days.ago, start_at: 10.days.ago,
        finish_at: 2.days.ago)

      expected = [attended, assigned].map { to_history_row(_1) }
      expect(history.recent_trainings).to match_array(expected)
    end

    it "does not list participations to other event types" do
      create_participation(event_type: :event, start_at: 10.days.ago, finish_at: 5.days.ago)
      course = create_course_participation(start_at: 10.days.ago, finish_at: 5.days.ago)
      create_tour_participation(start_at: 10.days.ago, finish_at: 5.days.ago)

      expect(history.recent_trainings).to match_array([to_history_row(course)])
    end
  end

  describe "#recent_tours" do
    it "lists tour participations ordered by finish_at and respects the limit" do
      first = create_tour_participation(start_at: 10.days.ago, finish_at: 5.days.ago)
      second = create_tour_participation(start_at: 13.days.ago, finish_at: 10.days.ago)
      third = create_tour_participation(start_at: 15.days.ago, finish_at: 12.days.ago)
      fourth = create_tour_participation(start_at: 30.days.ago, finish_at: 15.days.ago)
      fifth = create_tour_participation(start_at: 30.days.ago, finish_at: 20.days.ago)

      expected = [first, second, third, fourth, fifth].map { to_history_row(_1) }
      expect(history.recent_tours).to eq(expected)

      limit_expected = expected.take(3)
      expect(history.recent_tours(limit: 3)).to eq(limit_expected)
    end

    it "only lists past tour participations" do
      past = create_tour_participation(start_at: 10.days.ago, finish_at: 2.days.ago)
      create_tour_participation(start_at: 10.days.ago, finish_at: nil)
      create_tour_participation(start_at: 10.days.ago, finish_at: 2.days.from_now)
      create_tour_participation(start_at: 30.days.ago, finish_at: 20.days.ago).tap do |participation|
        participation.event.dates += [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.from_now)]
        participation.save!
      end

      expect(history.recent_tours).to match_array([to_history_row(past)])
    end

    it "only lists tour participations with active participation state" do
      attended = create_tour_participation(state: :attended, start_at: 10.days.ago, finish_at: 2.days.ago)
      assigned = create_tour_participation(state: :assigned, start_at: 10.days.ago, finish_at: 2.days.ago)
      create_tour_participation(state: :canceled, canceled_at: 20.days.ago, start_at: 10.days.ago,
        finish_at: 2.days.ago)
      create_tour_participation(state: :absent, canceled_at: 20.days.ago, start_at: 10.days.ago, finish_at: 2.days.ago)

      expected = [attended, assigned].map { to_history_row(_1) }
      expect(history.recent_tours).to match_array(expected)
    end

    it "does not list participations to other event types" do
      create_participation(event_type: :event, start_at: 10.days.ago, finish_at: 5.days.ago)
      create_course_participation(start_at: 10.days.ago, finish_at: 5.days.ago)
      tour = create_tour_participation(start_at: 10.days.ago, finish_at: 5.days.ago)

      expect(history.recent_tours).to match_array([to_history_row(tour)])
    end
  end

  describe "Row" do
    context "#from_event" do
      it "uses start_at from the oldest event date" do
        dates = [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 3.days.ago),
          Fabricate(:event_date, start_at: 25.days.ago, finish_at: 3.days.ago),
          Fabricate(:event_date, start_at: 23.days.ago, finish_at: 3.days.ago),
          Fabricate(:event_date, start_at: 20.days.ago, finish_at: 3.days.ago)]
        event = Fabricate(:sac_course, dates:)

        expect(Participations::History::Row.from_event(event).start_at).to eq(25.days.ago.to_date)
      end

      it "uses finish_at from most recent event date" do
        dates = [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 5.days.ago),
          Fabricate(:event_date, start_at: 25.days.ago, finish_at: 20.days.ago),
          Fabricate(:event_date, start_at: 23.days.ago, finish_at: 3.days.ago),
          Fabricate(:event_date, start_at: 20.days.ago, finish_at: 15.days.ago)]
        event = Fabricate(:sac_course, dates:)

        expect(Participations::History::Row.from_event(event).finish_at).to eq(3.days.ago.to_date)
      end

      it "uses group with lowest id as provider if there are multiple" do
        event = Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 20.days.ago, finish_at: 15.days.ago)],
          groups: [groups(:matterhorn), groups(:bluemlisalp)])

        expect(Participations::History::Row.from_event(event).provider).to eq(groups(:bluemlisalp).name)
      end
    end
  end

  def to_history_row(entry)
    if entry.is_a?(Event::Participation)
      Participations::History::Row.from_event(entry.event)
    elsif entry.is_a?(ExternalTraining)
      Participations::History::Row.from_external_training(entry)
    end
  end

  def create_external_training(start_at:, finish_at:, person: admin)
    Fabricate(:external_training, person:, start_at:, finish_at:)
  end

  def create_course_participation(start_at:, finish_at:, state: nil, canceled_at: nil, person: admin)
    create_participation(start_at:, finish_at:, state:, canceled_at:, event_type: :sac_course, person:)
  end

  def create_tour_participation(start_at:, finish_at:, state: nil, canceled_at: nil, person: admin)
    create_participation(start_at:, finish_at:, state:, canceled_at:, event_type: :sac_tour, person:)
  end

  def create_participation(start_at:, finish_at:, event_type:, state: nil, canceled_at: nil, person: admin)
    Fabricate(:event_participation, participant: person, state:, canceled_at:,
      event: Fabricate(event_type, dates: [Fabricate(:event_date, start_at:, finish_at:)]))
  end
end
