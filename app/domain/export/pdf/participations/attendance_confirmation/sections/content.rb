# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::AttendanceConfirmation::Sections::Content < Export::Pdf::Section
  include ActionView::Helpers::NumberHelper

  # Measured from the SAC template PDF
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
    render_description
    render_purpose
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

  def render_description
    paragraph(PARAGRAPH_SPACING) { text(event.plain_text_description.to_s) }
  end

  def render_purpose
    paragraph(PARAGRAPH_SPACING) { text(t(:purpose)) }
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
    event.dates.map { |date| date_range(date) }.join(", ")
  end

  def date_range(date)
    start_on = date.start_at.to_date
    finish_on = (date.finish_at || date.start_at).to_date
    return format_date(finish_on) if start_on == finish_on

    t(:date_range, start: format_date(start_on, range_start_format(start_on, finish_on)),
      finish: format_date(finish_on))
  end

  def range_start_format(start_on, finish_on)
    if start_on.year != finish_on.year
      :date_format
    elsif start_on.month != finish_on.month
      :date_format_without_year
    else
      :date_format_day_only
    end
  end

  def format_date(date, format = :date_format)
    I18n.l(date, format: t(format))
  end

  def paragraph(spacing = LINE_SPACING)
    pdf.move_down(spacing)
    yield
  end

  def bold(value) = "<b>#{escape(value)}</b>"

  def escape(value) = ERB::Util.html_escape(value.to_s)

  def t(key, **options) = I18n.t("participations.attendance_confirmation.#{key}", **options)
end
