# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# One chip per currently active agenda filter value, each carrying a path
# that re-applies every other filter unchanged while dropping just this
# value - rendered by agenda/_active_filter_chips.html.haml. Extracted from
# AgendaHelper so the chip-building logic (previously five private helper
# methods reaching into controller ivars) has its own explicit
# dependencies instead.
class AgendaFilterChips
  delegate :agenda_index_path, to: "Rails.application.routes.url_helpers"

  def initialize(event_filter, group, target_groups:, activities:,
    technical_requirements:, fitness_requirements:, traits:)
    @event_filter = event_filter
    @group = group
    @target_groups = target_groups
    @activities = activities
    @technical_requirements = technical_requirements
    @fitness_requirements = fitness_requirements
    @traits = traits
  end

  def chips
    params = @event_filter.chain.to_params.deep_dup.with_indifferent_access

    [
      date_range_chip(params, :since, I18n.t("agenda.filters.since")),
      date_range_chip(params, :until, I18n.t("agenda.filters.until")),
      full_text_chip(params),
      *essential_chips(params, :target_group_id, @target_groups),
      *essential_chips(params, :activity_id, @activities),
      *essential_chips(params, :technical_requirement_id, @technical_requirements),
      *essential_chips(params, :fitness_requirement_id, @fitness_requirements),
      *essential_chips(params, :trait_id, @traits)
    ].compact
  end

  private

  def date_range_chip(params, key, label)
    value = params.dig(:date_range, key)
    return if value.blank?
    return if key == :since && value == I18n.l(Time.zone.today)

    without = params.deep_dup
    without[:date_range] = without[:date_range].except(key)
    {label: "#{label}: #{value}", path: agenda_index_path(group_id: @group.id, filters: without)}
  end

  def boolean_chip(params, key, label)
    return unless params.dig(key, :value) == "1"

    without = params.deep_dup
    without.delete(key)
    {label: label, path: agenda_index_path(group_id: @group.id, filters: without)}
  end

  def full_text_chip(params)
    value = params.dig(:full_text, :q)
    return if value.blank?

    without = params.deep_dup
    without.delete(:full_text)
    {label: "\"#{value}\"", path: agenda_index_path(group_id: @group.id, filters: without)}
  end

  def essential_chips(params, key, entries)
    Array(params.dig(:tour_essentials, key)).filter_map do |id|
      entry = entries.find { |candidate| candidate.id == id }
      next unless entry

      without = params.deep_dup
      without[:tour_essentials][key] = without[:tour_essentials][key] - [id]
      {label: entry.to_s(:long), path: agenda_index_path(group_id: @group.id, filters: without)}
    end
  end
end
