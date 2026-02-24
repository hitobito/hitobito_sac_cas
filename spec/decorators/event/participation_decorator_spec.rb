# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacCas::Event::ParticipationDecorator do
  let(:admin) { people(:admin) }
  let(:participation) { Fabricate.build(:event_participation, participant: admin) }

  subject(:decorator) { participation.decorate }

  describe "#to_s" do
    it "returns person name" do
      expect(decorator.to_s).to eq "Anna Admin"
    end

    it "returns person name even when in revoked state" do
      allow(participation.event).to receive(:revoked_participation_states).and_return(%w[revoked])
      participation.state = "revoked"
      expect(decorator.to_s).to eq "Anna Admin"
    end
  end

  describe "#recent_trainings" do
    it "lists a mix of external trainings and course participations ordered by finish_at and respects the limit" do
      first = Fabricate(:external_training, person: admin, start_at: 10.days.ago, finish_at: 5.days.ago)
      second = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_course, dates: [Fabricate(:event_date, start_at: 13.days.ago, finish_at: 10.days.ago)]))
      third = Fabricate(:external_training, person: admin, start_at: 15.days.ago, finish_at: 12.days.ago)
      fourth = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_course, dates: [Fabricate(:event_date, start_at: 30.days.ago, finish_at: 15.days.ago)]))
      fifth = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_course, dates: [Fabricate(:event_date, start_at: 30.days.ago, finish_at: 20.days.ago)]))

      expected = [first, second, third, fourth, fifth].map { to_participation_history_row(_1) }
      expect(decorator.recent_trainings).to eq(expected)

      limit_expected = expected.take(3)
      expect(decorator.recent_trainings(limit: 3)).to eq(limit_expected)
    end

    it "only lists past course participations" do
      past = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_course, dates: [
          Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)
        ]))
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_course, dates: [
          Fabricate(:event_date, start_at: 10.days.ago, finish_at: nil)
        ]))
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_course, dates: [
          Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.from_now)
        ]))
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_course, dates: [
          Fabricate(:event_date, start_at: 30.days.ago, finish_at: 20.days.ago),
          Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.from_now)
        ]))

      expect(decorator.recent_trainings).to match_array([to_participation_history_row(past)])
    end

    it "only lists course participations with active participation state" do
      attended = Fabricate(:event_participation, participant: admin, state: :attended,
        event: Fabricate(:sac_course, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)]))
      assigned = Fabricate(:event_participation, participant: admin, state: :assigned,
        event: Fabricate(:sac_course, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)]))
      Fabricate(:event_participation, participant: admin, state: :canceled, canceled_at: 20.days.ago,
        event: Fabricate(:sac_course, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)]))
      Fabricate(:event_participation, participant: admin, state: :absent, canceled_at: 20.days.ago,
        event: Fabricate(:sac_course, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)]))

      expected = [attended, assigned].map { to_participation_history_row(_1) }
      expect(decorator.recent_trainings).to match_array(expected)
    end

    it "does not list participations to other event types" do
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:event, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 5.days.ago)]))
      course = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_course, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 5.days.ago)]))
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 5.days.ago)]))

      expect(decorator.recent_trainings).to match_array([to_participation_history_row(course)])
    end
  end

  describe "#recent_tours" do
    it "lists tour participations ordered by finish_at and respects the limit" do
      first = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 5.days.ago)]))
      second = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 13.days.ago, finish_at: 10.days.ago)]))
      third = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 15.days.ago, finish_at: 12.days.ago)]))
      fourth = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 30.days.ago, finish_at: 15.days.ago)]))
      fifth = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 30.days.ago, finish_at: 20.days.ago)]))

      expected = [first, second, third, fourth, fifth].map { to_participation_history_row(_1) }
      expect(decorator.recent_tours).to eq(expected)

      limit_expected = expected.take(3)
      expect(decorator.recent_tours(limit: 3)).to eq(limit_expected)
    end

    it "only lists past tour participations" do
      past = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [
          Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)
        ]))
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [
          Fabricate(:event_date, start_at: 10.days.ago, finish_at: nil)
        ]))
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [
          Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.from_now)
        ]))
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [
          Fabricate(:event_date, start_at: 30.days.ago, finish_at: 20.days.ago),
          Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.from_now)
        ]))

      expect(decorator.recent_tours).to match_array([to_participation_history_row(past)])
    end

    it "only lists tour participations with active participation state" do
      attended = Fabricate(:event_participation, participant: admin, state: :attended,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)]))
      assigned = Fabricate(:event_participation, participant: admin, state: :assigned,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)]))
      Fabricate(:event_participation, participant: admin, state: :canceled, canceled_at: 20.days.ago,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)]))
      Fabricate(:event_participation, participant: admin, state: :absent, canceled_at: 20.days.ago,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 2.days.ago)]))

      expected = [attended, assigned].map { to_participation_history_row(_1) }
      expect(decorator.recent_tours).to match_array(expected)
    end

    it "does not list participations to other event types" do
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:event, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 5.days.ago)]))
      Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_course, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 5.days.ago)]))
      tour = Fabricate(:event_participation, participant: admin,
        event: Fabricate(:sac_tour, dates: [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 5.days.ago)]))

      expect(decorator.recent_tours).to match_array([to_participation_history_row(tour)])
    end
  end

  def to_participation_history_row(entry)
    if entry.is_a?(Event::Participation)
      participation_to_history_row(entry)
    elsif entry.is_a?(ExternalTraining)
      training_to_history_row(entry)
    end
  end

  def participation_to_history_row(participation)
    event = participation.event
    SacCas::Event::ParticipationDecorator::ParticipationHistoryRow.new(
      name: event.name,
      start_at: event.dates.filter_map(&:start_at).min.to_date,
      finish_at: event.dates.filter_map(&:finish_at).max.to_date,
      provider: event.groups.min_by(&:id)&.name
    )
  end

  def training_to_history_row(training)
    SacCas::Event::ParticipationDecorator::ParticipationHistoryRow.new(
      name: training.name,
      start_at: training.start_at,
      finish_at: training.finish_at,
      provider: training.provider
    )
  end
end
