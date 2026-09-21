# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Events::Filter::FullText
  extend ActiveSupport::Concern

  MIN_QUERY_LENGTH = 3

  # Use custom table suffix to avoid collisions with joins of other filters
  TOUR_ESSENTIALS_ATTRS = [
    "event_target_group_translations_ft.label",
    "event_activity_translations_ft.label",
    "event_technical_requirement_translations_ft.label",
    "event_fitness_requirement_translations_ft.label",
    "event_trait_translations_ft.label",
    "leaders_ft.first_name",
    "leaders_ft.last_name"
  ]

  REQUIREMENT_ATTRS = [
    "event_technical_requirement_translations_ft.label",
    "event_fitness_requirement_translations_ft.short_label"
  ]

  prepended do
    Events::Filter::FullText::SEARCHABLE_ATTRIBUTES.push(
      "events.number",
      "events.location",
      "events.summit",
      "event_translations.additional_info",
      "event_translations.alternative_route",
      "event_translations.application_conditions",
      *TOUR_ESSENTIALS_ATTRS
    )

    TOUR_ESSENTIALS_ATTRS.each do |attr|
      SearchStrategies::SqlConditionBuilder.matchers[attr] =
        SearchStrategies::SqlConditionBuilder::StringMatcher
    end
  end

  def apply(scope)
    search_scope = scope
      .joins(join_essentials_and_parents("technical_requirement"))
      .joins(join_fitness_requirement)

    if short_words.present?
      search_scope = search_scope.where(requirements_condition)
    end
    if query.present?
      full_text_search(search_scope)
    else
      search_scope
    end
  end

  def full_text_search(scope)
    scope
      .joins(:translations)
      .joins(join_essentials("target_group"))
      .joins(join_essentials("trait"))
      .joins(join_essentials_and_parents("activity"))
      .joins(join_leaders)
      .where(search_condition)
  end

  def requirements_search(scope)
    scope.where(requirements_condition)
  end

  def blank?
    search_words.blank?
  end

  private

  def search_words
    @search_words ||= args[:q].to_s.strip.split(/\s+/)
  end

  def short_words
    @short_words ||= search_words.select { |word| word.size < MIN_QUERY_LENGTH }.map(&:downcase)
  end

  def query
    @query ||= search_words.select { |word| word.size >= MIN_QUERY_LENGTH }.join(" ")
  end

  # search short requirments with equality condition
  def requirements_condition
    short_words.map do |word|
      requirement_columns
        .map { |column| column.eq(word) }
        .reduce { |query, condition| query.or(condition) }
    end.reduce { |query, condition| query.and(condition) }
  end

  def requirement_columns
    REQUIREMENT_ATTRS.map do |attr|
      table, field = attr.split(".")
      Arel::Table.new(table)[field].lower
    end
  end

  def join_essentials(name)
    <<-SQL
      LEFT JOIN events_#{name.pluralize} AS events_#{name.pluralize}_ft ON
        events_#{name.pluralize}_ft.event_id = events.id
      LEFT JOIN event_#{name}_translations AS event_#{name}_translations_ft ON
        event_#{name}_translations_ft.event_#{name}_id = events_#{name.pluralize}_ft.#{name}_id
    SQL
  end

  def join_essentials_and_parents(name)
    <<-SQL
      LEFT JOIN events_#{name.pluralize} AS events_#{name.pluralize}_ft ON
        events_#{name.pluralize}_ft.event_id = events.id
      LEFT JOIN event_#{name.pluralize} AS event_#{name.pluralize}_ft ON
        event_#{name.pluralize}_ft.id = events_#{name.pluralize}_ft.#{name}_id
      LEFT JOIN event_#{name}_translations AS event_#{name}_translations_ft ON
        event_#{name}_translations_ft.event_#{name}_id = event_#{name.pluralize}_ft.id OR
        event_#{name}_translations_ft.event_#{name}_id = event_#{name.pluralize}_ft.parent_id
    SQL
  end

  def join_fitness_requirement
    <<-SQL
      LEFT JOIN event_fitness_requirement_translations AS
        event_fitness_requirement_translations_ft ON
        event_fitness_requirement_translations_ft.event_fitness_requirement_id =
          events.fitness_requirement_id
    SQL
  end

  def join_leaders
    <<-SQL
      LEFT JOIN event_cached_leaders AS event_cached_leaders_ft ON
        event_cached_leaders_ft.event_id = events.id
      LEFT JOIN people AS leaders_ft ON
        leaders_ft.id = event_cached_leaders_ft.person_id
    SQL
  end
end
