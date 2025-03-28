# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::KeyDataSheet::Sections::Table < Export::Pdf::Section
  FIRST_COLUMN_WIDTH = 120
  COMPENSATION_SUBTABLE_COLUMN_WIDTHS = [20, 80, 50, 70]
  ACCOMMODATION_BUDGET_SUBTABLE_COLUMN_WIDTHS = [50, 70]

  delegate :event, :person, :roles, to: :@model

  def render
    table(table_data)
  end

  def table_data
    [
      [t("number"), event.number],
      [t("name"), event.name],
      [t("level"), event.kind.level.label],
      [t("leaders"), leaders],
      *compensation_table,
      [t("event_dates_durations"), event_dates_durations],
      [t("event_dates_locations"), event_dates_locations],
      [t("accommodation"), accommodation],
      [t("accommodation_budget.label"), t("accommodation_budget.text")],
      *accommodation_budget_table,
      [t("accommodation_category"), event.accommodation_label],
      [t("language"), event.language_label],
      [t("content.label"), t("content.text")],
      [t("participant_requirements.label"), t("participant_requirements.text")],
      [t("participant_program_course.label"), t("participant_program_course.text")],
      [t("participant_program_tour.label"), t("participant_program_tour.text")],
      [t("application_closing_at"), localize_date(event.application_closing_at&.to_date)],
      [t("minimum_participants"), event.minimum_participants],
      [t("maximum_participants"), event.maximum_participants],
      [t("participation_yes_no.label"), t("participation_yes_no.text")],
      [t("participation_cancellation.label"), t("participation_cancellation.text")],
      [t("ideal_class_size"), event.ideal_class_size],
      [t("maximum_class_size"), event.maximum_class_size],
      [t("class_teacher.label"), t("class_teacher.text")]
    ]
  end

  def table(data)
    pdf.table(data, header: false, width: bounds.width, column_widths: {0 => FIRST_COLUMN_WIDTH}, cell_style: {border_width: 0.5}) do
      # cells.padding = [7, 7, 7, 5] doesnt work well with subtables
    end
  end

  def leaders
    event.participations.select do |p|
      p.roles.any? { _1.class.leader? }
    end.map { _1.person.full_name }.join(", ")
  end

  def event_dates_durations
    event.dates.map do |date|
      [localize_date(date.start_at.to_date), localize_date(date.finish_at&.to_date)].join(" - ")
    end.join("\n")
  end

  def compensation_table
    event_compensation_rates(:day).map { |rate| compensation_row(rate) } +
      event_compensation_rates(:flat).map { |rate| compensation_row(rate) }
  end

  def compensation_row(rate)
    table_width = bounds.width - FIRST_COLUMN_WIDTH

    column_widths = [table_width - COMPENSATION_SUBTABLE_COLUMN_WIDTHS.sum] + COMPENSATION_SUBTABLE_COLUMN_WIDTHS
    event_days = (rate.course_compensation_category.kind == :day) ? event.total_event_days : 1
    ["",
      make_subtable([[compensation_category_name(rate),
        event_days,
        rate.course_compensation_category.kind_label,
        "à CHF",
        compensation_rate(rate)]],
        column_widths:)]
  end

  def accommodation_budget_table
    table_width = bounds.width - FIRST_COLUMN_WIDTH

    column_widths = [table_width - ACCOMMODATION_BUDGET_SUBTABLE_COLUMN_WIDTHS.sum] + ACCOMMODATION_BUDGET_SUBTABLE_COLUMN_WIDTHS
    event_compensation_rates(:budget).map do |rate|
      [
        "",
        make_subtable([[
          compensation_category_name(rate),
          "CHF",
          compensation_rate(rate)
        ]], column_widths:)
      ]
    end
  end

  def event_compensation_rates(kind)
    event.compensation_rates.includes(:course_compensation_category)
      .where(course_compensation_categories: {kind: kind})
  end

  def compensation_category_name(rate)
    rate.course_compensation_category.send(:"name_#{participation_leader_type}").presence ||
      rate.course_compensation_category.short_name
  end

  def compensation_rate(rate)
    rate.send(:"rate_#{participation_leader_type}")
  end

  def make_subtable(data, options = {})
    pdf.make_table(data, options.reverse_merge(width: bounds.width - FIRST_COLUMN_WIDTH, cell_style: {border_width: 0.5}))
  end

  def event_dates_locations
    event.dates.pluck(:location).join("\n")
  end

  def accommodation
    key = event.reserve_accommodation? ? "sac" : "event_specific"

    t("accommodations.#{key}")
  end

  def participation_leader_type
    if roles.any? { _1.is_a?(Event::Course::Role::Leader) }
      :leader
    else
      :assistant_leader
    end
  end

  def t(key, options = {})
    I18n.t("participations.key_data_sheet.table.#{key}", **options)
  end

  def localize_date(date)
    date.present? ? I18n.l(date.to_date) : ""
  end
end
