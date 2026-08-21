# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module AgendaHelper
  # Icon paths copied verbatim from the Lucide icon set (https://lucide.dev,
  # ISC licensed), matching exactly what the Tourenportal prototype uses -
  # the agenda pages render these as inline SVGs instead of pulling in
  # FontAwesome (see agenda_icon below).
  AGENDA_ICONS = {
    "mountain" => '<path d="m8 3 4 8 5-5 5 15H2L8 3z" />',
    "users" => '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />' \
      '<path d="M16 3.128a4 4 0 0 1 0 7.744" />' \
      '<path d="M22 21v-2a4 4 0 0 0-3-3.87" />' \
      '<circle cx="9" cy="7" r="4" />',
    "activity" => '<path d="M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0' \
      'L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2" />',
    "tag" => '<path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 ' \
      '.586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z" />' \
      '<circle cx="7.5" cy="7.5" r=".5" fill="currentColor" />',
    "calendar-check" => '<path d="M8 2v3" /><path d="M16 2v3" />' \
      '<rect x="3" y="3" width="18" height="18" rx="2" /><path d="M3 9h18" />' \
      '<path d="m9 15 2 2 4-4" />',
    "x" => '<path d="M18 6 6 18" /><path d="m6 6 12 12" />',
    "calendar" => '<path d="M8 2v3" /><path d="M16 2v3" />' \
      '<rect x="3" y="3" width="18" height="18" rx="2" /><path d="M3 9h18" />',
    "clock" => '<circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" />',
    "gauge" => '<path d="m12 14 4-4" /><path d="M3.34 19a10 10 0 1 1 17.32 0" />',
    "trending-up" => '<path d="M16 7h6v6" /><path d="m22 7-8.5 8.5-5-5L2 17" />',
    "user" => '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />' \
      '<circle cx="12" cy="7" r="4" />',
    "rotate-ccw" => '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />' \
      '<path d="M3 3v5h5" />',
    "chevron-down" => '<path d="m6 9 6 6 6-6" />',
    "search" => '<path d="m21 21-4.34-4.34" /><circle cx="11" cy="11" r="8" />'
  }.freeze

  # Renders one of the icons above as an inline SVG, sized/coloured via CSS
  # (currentColor + the .agenda-icon class) exactly like the prototype's
  # Lucide icons - never FontAwesome, which the agenda pages don't load.
  def agenda_icon(name, css_class: nil)
    content_tag(:svg, AGENDA_ICONS.fetch(name.to_s).html_safe,
      xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round",
      "stroke-linejoin": "round", class: ["agenda-icon", css_class].compact.join(" "),
      "aria-hidden": "true", focusable: "false")
  end

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
      full_text_chip(params, group),
      *essential_chips(params, group, :target_group_id, @target_groups),
      *essential_chips(params, group, :activity_id, @activities),
      *essential_chips(params, group, :technical_requirement_id, @technical_requirements),
      *essential_chips(params, group, :fitness_requirement_id, @fitness_requirements)
    ].compact
  end

  # Every distinct discipline (main activity) a tour belongs to, with its
  # colour, in the order its activities were assigned - used for the
  # coloured discipline badges on a tour card. Only Event::Tour has
  # activities - other event types (e.g. Event::Course) have none.
  def tour_disciplines(event)
    return [] unless event.is_a?(Event::Tour)

    event.activities.filter_map { |activity| activity.main? ? activity : activity.parent }
      .uniq(&:id)
      .map { |main| {label: main.label, color: main.color} }
  end

  # The discipline colour to accent a tour card with, resolved from the
  # tour's first activity.
  def tour_accent_color(event)
    tour_disciplines(event).first&.fetch(:color)
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

  def full_text_chip(params, group)
    value = params.dig(:full_text, :q)
    return if value.blank?

    without = params.deep_dup
    without.delete(:full_text)
    {label: "\"#{value}\"", path: agenda_index_path(group_id: group.id, filters: without)}
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
