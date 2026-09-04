# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module AgendaHelper
  def agenda_icon(name, **attributes)
    AgendaIcon.new(name).to_svg(**attributes)
  end

  def agenda_activity_icon(activity)
    return unless activity.parent&.icon&.attached?

    options = {"aria-hidden": "true"}
    if activity.description?
      options[:title] =
        "<strong class='text-black'>#{activity.label}</strong><br>#{activity.description}"
      options[:data] = {bs_toggle: :tooltip, bs_placement: :top, bs_html: "true"}
    end
    content_tag(:span,
      event_activity_icon(activity.parent, class: "agenda-icon"),
      class: "agenda-activity-icon",
      **options)
  end

  def tour_accent_color(event)
    return nil unless event.tour?

    event.activities.map(&:parent).compact.min_by(&:order)&.color
  end

  def tour_activity_requirements(event)
    event.activities
      .filter(&:technical_requirement_id)
      .uniq(&:technical_requirement_id)
      .index_with do |activity|
      event.technical_requirements
        .filter { |r| r.parent_id == activity.technical_requirement_id }
        .sort_by(&:order)
    end.reject { |_, requirements| requirements.empty? }
  end

  def agenda_info_block(content)
    html = safe_auto_link(content, html: {target: "_blank"})
    simple_format(html, {}, sanitize_options: {attributes: %w[href target]})
  end

  def agenda_fact(icon, label, &block)
    content_tag(:div, class: "agenda-fact") do
      agenda_icon(icon) +
        content_tag(:div, class: "agenda-fact-body") do
          content_tag(:div, label, class: "agenda-fact-label") +
            content_tag(:div, class: "agenda-fact-value", &block)
        end
    end
  end

  def agenda_meta_row(icon, tooltip: nil, &block)
    options = {}
    if tooltip.present?
      options = {
        title: tooltip,
        data: {bs_toggle: :tooltip, bs_placement: :top, bs_html: true}
      }
    end
    content_tag(:span, class: "agenda-tour-card-meta-row", **options) do
      agenda_icon(icon) + capture(&block)
    end
  end

  # The given values, each on its own line. Keeps a newline next to the <br>
  # so that text extraction and screen readers don't run them together.
  def agenda_lines(values)
    safe_join(values, tag.br + "\n")
  end

  def agenda_date_labels(event)
    separator = " - "
    event.dates.map do |date|
      duration = Duration.new(
        date.start_at.to_date,
        date.finish_at&.to_date,
        date_format: :with_day
      ).to_s(:short)
      safe_join(
        duration
          .split(separator)
          .map { |part| content_tag(:span, part, class: "text-nowrap") },
        separator
      )
    end
  end

  def agenda_participant_count(event)
    return unless event.display_booking_info?

    [event.participant_count, event.maximum_participants].compact.join("/")
  end

  def agenda_max_participants_label(event)
    return if event.display_booking_info? || !event.maximum_participants?

    t("agenda.list.tour_card.max_participants", max: event.maximum_participants)
  end

  def agenda_status_badge(event)
    status = event.agenda_status
    return unless status

    tag.span(t("agenda.status.#{status}"),
      class: "agenda-status-badge agenda-status-#{status}")
  end

  def agenda_outline_badge(essential)
    tag.span(
      essential.label,
      class: "agenda-badge-outline",
      title: essential.description,
      data: {bs_toggle: :tooltip, bs_placement: :bottom}
    )
  end

  def agenda_apply_button(event, group)
    return unless event.application_possible?

    waiting = !event.places_available? && event.display_booking_info?
    link_to t("agenda.buttons.#{waiting ? "waiting_list" : "apply"}"),
      contact_data_group_event_participations_path(group, event),
      class: "btn btn-sm agenda-btn-cta agenda-btn-positive"
  end

  def agenda_application_deadline(event)
    if event.application_possible? && event.application_closing_at.present?
      {label: Event.human_attribute_name(:application_closing_at),
       value: l(event.application_closing_at)}
    elsif event.application_opening_at&.future?
      {label: Event.human_attribute_name(:application_opening_at),
       value: l(event.application_opening_at)}
    end
  end

  def event_leader_participations(event)
    event.participations_for(*event.class.leader_types)
  end

  def person_initials(person)
    person.to_s.split.filter_map { |word| word[0] }.first(2).join.upcase
  end

  def tour_price_categories(event)
    return [] unless event.tour?

    event.possible_price_categories.filter_map do |attribute|
      amount = event.public_send(attribute)
      next if amount.blank?

      formatted = number_with_precision(amount, precision: 2, strip_insignificant_zeros: true)
      "#{t("agenda.show.price.#{attribute}")} CHF #{formatted}"
    end
  end
end
