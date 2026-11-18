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
      .left_outer_joins(translations: :rich_text_description)
      .joins(join_essentials("target_group"))
      .joins(join_essentials("trait"))
      .joins(join_essentials_and_parents("activity"))
      .joins(join_leaders)
      .where(search_condition)
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

  def long_words
    @long_words ||= search_words.select { |word| word.size >= MIN_QUERY_LENGTH }
  end

  def query
    @query ||= long_words.join(" ")
  end

  # search short requirements with equality condition
  def requirements_condition
    short_words.map do |code|
      REQUIREMENT_ATTRS.map { |column| code_equals(column, code) }.reduce(:or)
    end.reduce(:and)
  end

  # Labels matching no search word cannot satisfy the search condition, but would multiply rows.
  def join_essentials(name)
    <<~SQL
      LEFT JOIN (
        SELECT events_#{name.pluralize}.event_id, event_#{name}_translations_ft.label
        FROM events_#{name.pluralize}
        INNER JOIN event_#{name}_translations AS event_#{name}_translations_ft ON
          event_#{name}_translations_ft.event_#{name}_id = events_#{name.pluralize}.#{name}_id
        WHERE #{any_word_matches("event_#{name}_translations_ft.label")}
      ) AS event_#{name}_translations_ft ON event_#{name}_translations_ft.event_id = events.id
    SQL
  end

  def join_essentials_and_parents(name)
    label = "event_#{name}_translations_ft.label"
    <<~SQL
      LEFT JOIN (
        SELECT events_#{name.pluralize}.event_id, #{label}
        FROM events_#{name.pluralize}
        INNER JOIN event_#{name.pluralize} ON
          event_#{name.pluralize}.id = events_#{name.pluralize}.#{name}_id
        INNER JOIN event_#{name}_translations AS event_#{name}_translations_ft ON
          event_#{name}_translations_ft.event_#{name}_id IN
            (event_#{name.pluralize}.id, event_#{name.pluralize}.parent_id)
        WHERE #{any_word_matches(label)} OR #{any_code_equals(label)}
      ) AS event_#{name}_translations_ft ON event_#{name}_translations_ft.event_id = events.id
    SQL
  end

  def join_fitness_requirement
    <<~SQL
      LEFT JOIN event_fitness_requirement_translations AS event_fitness_requirement_translations_ft ON
        event_fitness_requirement_translations_ft.event_fitness_requirement_id =
          events.fitness_requirement_id AND
        (#{any_word_matches("event_fitness_requirement_translations_ft.label")} OR
          #{any_code_equals("event_fitness_requirement_translations_ft.short_label")})
    SQL
  end

  def join_leaders
    <<~SQL
      LEFT JOIN (
        SELECT event_cached_leaders.event_id, leaders_ft.first_name, leaders_ft.last_name
        FROM event_cached_leaders
        INNER JOIN people AS leaders_ft ON leaders_ft.id = event_cached_leaders.person_id
        WHERE #{any_word_matches("leaders_ft.first_name", "leaders_ft.last_name")}
      ) AS leaders_ft ON leaders_ft.event_id = events.id
    SQL
  end

  def any_word_matches(*columns)
    any_of(columns.product(long_words).map do |column, word|
      SearchStrategies::SqlConditionBuilder.new(word, [column]).search_conditions.to_sql
    end)
  end

  def any_code_equals(column)
    any_of(short_words.map { |code| code_equals(column, code).to_sql })
  end

  def code_equals(column, code)
    table, field = column.split(".")
    Arel::Table.new(table)[field].lower.eq(code)
  end

  def any_of(conditions)
    conditions.empty? ? "FALSE" : conditions.map { |condition| "(#{condition})" }.join(" OR ")
  end
end
