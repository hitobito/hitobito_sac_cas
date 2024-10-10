# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::KeyDataSheet::Sections::Table < Export::Pdf::Section
  FIRST_COLUMN_WIDTH = 120

  def render
    table(table_data)
  end

  def table_data
    [
      [t("number"), event.number],
      [t("name"), event.name],
      [t("level"), event.kind.level.label],
      [t("leaders"), leaders],
      [t("compensation"), ""],
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
    event_dates.map do |date|
      [localize_date(date.start_at.to_date), localize_date(date.finish_at&.to_date)].join(" - ")
    end.join("\n")
  end

  def compensation_table
    scope = valid_course_compensation_categories_scope.where(kind: [:day, :flat])

    scope.map do |category|
      compensation_row(category)
    end
  end

  def compensation_row(compensation_category)
    event_days = (compensation_category.kind == :day) ? total_event_days : 1
    ["",
      make_subtable([[compensation_category.send(:"name_#{participation_leader_type}"),
        event_days,
        compensation_category.kind_label,
        "à CHF",
        compensation_category.current_compensation_rate(event_start_at).send(:"rate_#{participation_leader_type}")]])]
  end

  def accommodation_budget_table
    valid_course_compensation_categories_scope.where(kind: :budget).includes(:course_compensation_rates).list.map do |category|
      [
        "",
        make_subtable([[
          category.short_name,
          "CHF",
          category.current_compensation_rate.rate_leader # what about rate_assistant_leader?
        ]])
      ]
    end.presence || [["", ""]]
  end

  def make_subtable(data, options = {})
    pdf.make_table(data, options.reverse_merge(width: bounds.width - FIRST_COLUMN_WIDTH))
  end

  def event_dates_locations
    event_dates.pluck(:location).join("\n")
  end

  def valid_course_compensation_categories_scope
    event.kind.course_compensation_categories
      .joins(:course_compensation_rates)
      .where("(:start_at >= valid_from) AND (valid_to IS NULL OR valid_to >= :start_at)", start_at: event_start_at)
  end

  def accommodation
    key = event.reserve_accommodation? ? "sac" : "event_specific"

    t("accommodations.#{key}")
  end

  def participation_leader_type
    if @model.roles.any? { _1.is_a?(Event::Role::Leader) }
      :leader
    else
      :assistant_leader
    end
  end

  def event_dates
    @event_dates ||= event.dates.order(start_at: :asc)
  end

  def total_event_days
    @total_event_days ||= begin
      total_event_days = event.dates.sum { _1.duration.days }
      total_event_days -= 0.5 if event.start_point_of_time == :evening
      total_event_days
    end
  end

  def event_start_at
    @event_start_at ||= event.dates.order(start_at: :asc).first.start_at
  end

  def event
    @event ||= @model.event
  end

  def person
    @person ||= @model.person
  end

  def t(key, options = {})
    I18n.t("participations.key_data_sheet.table.#{key}", **options)
  end

  def localize_date(date)
    date.present? ? I18n.l(date.to_date) : ""
  end
end
