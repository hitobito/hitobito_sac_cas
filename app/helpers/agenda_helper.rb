# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module AgendaHelper
  def show_places_available_filter?(group)
    group.events.future.where(
      state: %w[published ready closed canceled],
      type: Event::Tour.sti_name,
      display_booking_info: true
    ).exists?
  end

  # One chip per currently active filter value, each carrying a path that
  # re-applies every other filter unchanged while dropping just this value.
  def active_filter_chips(event_filter, group)
    params = event_filter.chain.to_params.deep_dup.with_indifferent_access

    [
      date_range_chip(params, group, :since, t("agenda.date_filters.since")),
      date_range_chip(params, group, :until, t("agenda.date_filters.until")),
      boolean_chip(params, group, :application_open,
        t("agenda.application_filters.application_open")),
      boolean_chip(params, group, :places_available,
        t("agenda.application_filters.places_available")),
      *essential_chips(params, group, :target_group_id, @target_groups),
      *essential_chips(params, group, :activity_id, @activities),
      *essential_chips(params, group, :technical_requirement_id, @technical_requirements),
      *essential_chips(params, group, :fitness_requirement_id, @fitness_requirements)
    ].compact
  end

  # The discipline colour to accent a tour card with, resolved from the
  # tour's (leaf-level) activity via its main activity's colour. Only
  # Event::Tour has activities - other event types (e.g. Event::Course)
  # have no accent colour.
  def tour_accent_color(event)
    return unless event.is_a?(Event::Tour)

    activity = event.activities.first
    return if activity.nil?

    activity.main? ? activity.color : activity.parent&.color
  end

  private

  def date_range_chip(params, group, key, label)
    value = params.dig(:date_range, key)
    return if value.blank?
    return if key == :since && value == I18n.l(Time.zone.today)

    without = params.deep_dup
    without[:date_range] = without[:date_range].except(key)
    {label: "#{label}: #{value}", path: agenda_index_path(group_id: group.id, filters: without)}
  end

  def boolean_chip(params, group, key, label)
    return unless params.dig(key, :value) == "1"

    without = params.deep_dup
    without.delete(key)
    {label: label, path: agenda_index_path(group_id: group.id, filters: without)}
  end

  def essential_chips(params, group, key, entries)
    Array(params.dig(:tour_essentials, key)).filter_map do |id|
      entry = entries.find { |candidate| candidate.id == id }
      next unless entry

      without = params.deep_dup
      without[:tour_essentials][key] = without[:tour_essentials][key] - [id]
      {label: entry.label, path: agenda_index_path(group_id: group.id, filters: without)}
    end
  end
end
