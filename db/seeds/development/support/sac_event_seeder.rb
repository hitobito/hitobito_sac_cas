# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("db", "seeds", "support", "event_seeder")

class SacEventSeeder < EventSeeder
  def seed_event(group_id, type)
    values = event_values(group_id)
    case type
    when :course then seed_course(values)
    when :tour then seed_tour(values)
    when :base then seed_base_event(values)
    end
  end

  # rubocop:todo Metrics/MethodLength
  def seed_tour(values) # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/MethodLength
    attrs = tour_attributes(values)
    event = Event::Tour
      .joins(:groups)
      .where(groups: {id: values[:group_ids]})
      .find_or_initialize_by(name: attrs[:name])
    event.attributes = attrs
    event.save(validate: false)

    date = values[:application_opening_at] + rand(180).days
    Event::Date.seed(:event_id, :start_at, {
      event_id: event.id,
      start_at: date,
      finish_at: date + rand(2).days
    })
    seed_questions(event)
    seed_leaders(event)
    seed_participants(event)

    event
  end
  # rubocop:enable Metrics/MethodLength

  def tour_attributes(values)
    values.merge({
      name: Faker::Mountain.name,
      state: Event::Tour.possible_states.sample,
      automatic_assignment: true,
      priorization: false,
      requires_approval: false,
      external_applications: true
    })
  end

  def course_attributes(values)
    super.merge(
      cost_center: CostCenter.first,
      cost_unit: CostUnit.first,
      language: :de,
      season: Event::Kind::SEASONS.sample,
      start_point_of_time: :day,
      automatic_assignment: true,
      priorization: false,
      requires_approval: false,
      contact_id: Person.last.id,
      price_member: 10,
      price_regular: 20,
      number: "#{current_year - rand(5)}-#{rand(100000)}"
    )
  end

  def seed_questions(event)
    event.init_questions
    event.application_questions.map do |question|
      if question.question == "Notfallkontakt 1 - Name und Telefonnummer"
        question.update(disclosure: :required)
      else
        question.update(disclosure: :optional)
      end
    end
  end

  def seed_participation(event)
    super.tap do |participation|
      attrs = {state: event.possible_participation_states.sample}
      attrs[:canceled_at] = rand(100).days.ago if attrs[:state] == "canceled"
      participation.update!(attrs)
    end
  end

  def current_year
    @current_year ||= Time.zone.today.year
  end
end
