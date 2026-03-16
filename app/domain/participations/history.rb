# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Participations::History
  Row = Data.define(:name, :start_at, :finish_at, :provider) do
    def daterange = [I18n.l(start_at), I18n.l(finish_at)].join("-")

    def <=>(other)
      return unless other.is_a?(self.class)

      finish_at <=> other.finish_at
    end

    def self.from(entry)
      if entry.is_a?(Event)
        from_event(entry)
      elsif entry.is_a?(Event::Participation)
        from_event(entry.event)
      elsif entry.is_a?(ExternalTraining)
        from_external_training(entry)
      end
    end

    def self.from_external_training(training)
      new(
        name: training.name,
        start_at: training.start_at,
        finish_at: training.finish_at,
        provider: training.provider
      )
    end

    def self.from_event(event)
      new(
        name: event.name,
        start_at: event.dates.filter_map(&:start_at).min.to_date,
        finish_at: event.dates.filter_map(&:finish_at).max.to_date,
        provider: event.groups.min_by(&:id)&.layer_group&.name
      )
    end
  end

  attr_reader :person

  def initialize(person)
    @person = person
  end

  def recent_trainings(limit: nil)
    list = (recent_external_trainings(limit:) + recent_participations(event_type: Event::Course,
      limit:))
      .sort
    list = list.last(limit) if limit
    list.reverse
  end

  def recent_tours(limit: nil)
    recent_participations(event_type: Event::Tour, limit:)
  end

  private

  def recent_external_trainings(limit: nil)
    person.external_trainings # external_trainings can only be in the past
      .order(finish_at: :desc)
      .limit(limit)
      .map { |training| Row.from(training) }
  end

  def recent_participations(event_type: Event, limit: nil)
    person.event_participations.in_the_past
      .joins(event: :dates)
      .where(state: event_type.active_participation_states,
        events: {type: event_type.sti_name})
      .group("event_participations.id")
      .order("MAX(event_dates.finish_at) DESC")
      .includes(event: [:translations, :dates, :groups])
      .limit(limit)
      .map { |participation| Row.from(participation) }
  end
end
