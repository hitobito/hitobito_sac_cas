# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module AgendaHelper
  # Shorthand for the agenda pages' inline icons, see AgendaIcon.
  def agenda_icon(name, **attributes)
    AgendaIcon.new(name).to_svg(**attributes)
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

  def tour_altitude_difference(event)
    labels = []
    labels << "↑ #{event.ascent} #{t("agenda.show.meters_abbreviation")}" if event.ascent?
    labels << "↓ #{event.descent} #{t("agenda.show.meters_abbreviation")}" if event.descent?

    safe_join(labels, " / ")
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

  def agenda_meta_row(icon, &block)
    content_tag(:span, class: "agenda-tour-card-meta-row") do
      agenda_icon(icon) + capture(&block)
    end
  end

  # The given values, each on its own line. Keeps a newline next to the <br>
  # so that text extraction and screen readers don't run them together.
  def agenda_lines(values)
    safe_join(values, tag.br + "\n")
  end

  # One formatted label per date of the event, e.g. "Mo 02.03.2026".
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

  # "3/12", "3" or nil - the booked places, but only for events that publish
  # their booking info at all.
  def agenda_participant_count(event)
    return unless event.display_booking_info?

    [event.participant_count, event.maximum_participants].compact.join("/")
  end

  # The participant limit for events that don't publish their booking info,
  # nil for those that do or that have no limit worth mentioning.
  def agenda_max_participants_label(event)
    return if event.display_booking_info? || !event.maximum_participants?

    t("agenda.list.tour_card.max_participants", max: event.maximum_participants)
  end

  # The event's current status as a badge, nil for the event types that have
  # no agenda status at all.
  def agenda_status_badge(event)
    status = event.agenda_status
    return unless status

    tag.span(t("agenda.status.#{status}"),
      class: "agenda-status-badge agenda-status-#{status}")
  end

  # The tour's target groups and traits as outline badges. Just the badges,
  # without a row around them: the two agenda views place them differently
  # relative to the status badge.
  def agenda_outline_badges(event)
    return unless event.tour?

    safe_join((event.target_groups + event.traits)
      .map { |entry| tag.span(entry.label, class: "agenda-badge-outline") }, "\n")
  end

  # The call to action for an event one can still apply for, nil otherwise.
  # Note that this asks the event about its places rather than reading
  # #agenda_status: a course reports :application_waiting whenever it is
  # full, no matter whether it publishes its booking info.
  def agenda_apply_button(event, group)
    return unless event.application_possible?

    waiting = !event.places_available? && event.display_booking_info?
    link_to t("agenda.buttons.#{waiting ? "waiting_list" : "apply"}"),
      contact_data_group_event_participations_path(group, event),
      class: "btn btn-sm agenda-btn-cta agenda-btn-positive"
  end

  # The application deadline or, as long as the application has not opened
  # yet, the opening date - whichever of the two is currently relevant.
  # Returns the parts rather than a finished string because the two agenda
  # views emphasize them differently.
  def agenda_application_deadline(event)
    if event.application_possible? && event.application_closing_at.present?
      {label: Event.human_attribute_name(:application_closing_at),
       value: l(event.application_closing_at)}
    elsif event.application_opening_at&.future?
      {label: Event.human_attribute_name(:application_opening_at),
       value: l(event.application_opening_at)}
    end
  end

  # The leader/co-leader people for an event (never participants/helpers),
  # in role order - there's no ready-made "leaders" association (the
  # `leaders` attr_accessor on Event::Tour is for Event::TourResource, not
  # a DB relation), so this goes through the same Participatable API the
  # rest of the app uses to look up people by role kind.
  def event_leader_participations(event)
    event.participations_for(*event.class.leader_types)
  end

  # "Viviane Fischer" -> "VF", matching the prototype's fallback avatar for
  # a leader with no picture.
  def person_initials(person)
    person.to_s.split.filter_map { |word| word[0] }.first(2).join.upcase
  end

  # Every price category this tour currently charges, labelled for public
  # display - Event::Tour::PRICE_ATTRIBUTES' own human_attribute_name
  # (e.g. "Kosten SAC-Mitglied (extern)") is written for the edit form, not
  # an inline cost list, hence the shorter agenda-scoped labels.
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
