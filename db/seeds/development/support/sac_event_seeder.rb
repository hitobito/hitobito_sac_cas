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
    seed_essentials(event)

    event
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize
  def tour_attributes(values)
    values.merge({
      name: Faker::Mountain.name,
      state: Event::Tour.possible_states.sample,
      automatic_assignment: true,
      priorization: false,
      requires_approval: false,
      external_applications: true,
      technical_requirements: [Event::TechnicalRequirement.assignable.sample],
      fitness_requirement: Event::FitnessRequirement.assignable.sample,
      disciplines: [Event::Discipline.assignable.sample],
      target_groups: [Event::TargetGroup.assignable.sample],
      subito: [true, false].sample,
      season: Event::Kind::SEASONS.sample
    })
  end
  # rubocop:enable Metrics/AbcSize

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

  def seed_essentials(event)
    event.disciplines = disciplines.sample(rand(1..3))
    event.target_groups = target_groups.sample(rand(1..2))
    event.fitness_requirement = fitness_requirements.sample
    event.technical_requirements = technical_requirements.sample(rand(1..2))
    event.traits = traits.sample(rand(0..2))
  end

  def current_year
    @current_year ||= Time.zone.today.year
  end

  def disciplines
    @disciplines ||= Event::Discipline.where.not(parent_id: nil).to_a
  end

  def target_groups
    @target_groups ||= Event::TargetGroup.all.to_a
  end

  def technical_requirements
    @technical_requirements ||= Event::TechnicalRequirement.where.not(parent_id: nil).to_a
  end

  def fitness_requirements
    @fitness_requirements ||= Event::FitnessRequirement.all.to_a
  end

  def traits
    @traits ||= Event::Trait.where.not(parent_id: nil).to_a
  end
end
