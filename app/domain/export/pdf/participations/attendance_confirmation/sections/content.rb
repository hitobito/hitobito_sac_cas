# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::AttendanceConfirmation::Sections::Content < Export::Pdf::Section
  include ActionView::Helpers::NumberHelper

  TITLE_TOP = 271.3
  TITLE_SPACING = 48.2
  LINE_SPACING = 7.5
  PARAGRAPH_SPACING = 12
  CLOSING_SPACING = 27.8

  delegate :event, :person, to: :model

  def render
    render_title
    render_confirmation
    render_course_details
    paragraph(PARAGRAPH_SPACING) { text(event.plain_text_description.to_s) }
    paragraph(PARAGRAPH_SPACING) { text(t(:purpose)) }
    render_closing
  end

  private

  def render_title
    offset_cursor_from_top(TITLE_TOP)
    text(t(:title), style: :bold)
    pdf.move_down(TITLE_SPACING)
  end

  def render_confirmation
    text(t(:intro))
    paragraph { text(person.full_name, style: :bold) }
    paragraph do
      text(t(:course_attended, course: bold("#{event.name} #{event.number}")), inline_format: true)
    end
  end

  def render_course_details
    paragraph do
      course_details.each do |label, value|
        text("#{bold("#{t(label)}:")} #{escape(value)}", inline_format: true)
      end
    end
  end

  def render_closing
    paragraph(CLOSING_SPACING) { text(t(:greeting), style: :bold) }
    text(t(:sender))
    paragraph(CLOSING_SPACING) { text(t(:signature)) }
  end

  def course_details
    {
      location: event.location.to_s.split("\n").join(", "),
      dates: dates,
      number: event.number,
      price: number_to_currency(model.price || 0, unit: "CHF", format: "%u %n")
    }
  end

  def dates
    start_on = event.dates.map(&:start_at).min.to_date
    finish_on = event.dates.map { |date| date.finish_at || date.start_at }.max.to_date
    return format_date(finish_on) if start_on == finish_on

    t(:date_range, start: format_date(start_on, with_year: start_on.year != finish_on.year),
      finish: format_date(finish_on))
  end

  def format_date(date, with_year: true)
    I18n.l(date, format: t(with_year ? :date_format : :date_format_without_year))
  end

  def paragraph(spacing = LINE_SPACING)
    pdf.move_down(spacing)
    yield
  end

  def bold(value) = "<b>#{escape(value)}</b>"

  def escape(value) = ERB::Util.html_escape(value.to_s)

  def t(key, **options) = I18n.t("participations.attendance_confirmation.#{key}", **options)
end
