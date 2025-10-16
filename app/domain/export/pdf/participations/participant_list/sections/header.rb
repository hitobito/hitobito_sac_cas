# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::ParticipantList::Sections::Header < Export::Pdf::Section
  def render
    render_header
    render_title
    render_info
  end

  def render_header
    pdf.text("<link href=\"#{t(:url)}\">#{t(:link)}</link>", inline_format: true)
  end

  def render_title
    pdf.move_down 1.5.cm
    pdf.font_size(10) do
      pdf.text(t(:title), style: :bold)
    end
  end

  def render_info
    pdf.move_down 0.5.cm
    pdf.table(info_data, cell_style: {borders: [], padding: [0, 0.5.cm, 0, 0], single_line: true})
    pdf.move_down 0.5.cm
  end

  def info_data # rubocop:todo Metrics/AbcSize
    [
      [t(:number), course_number_link],
      [t(:name), course.name],
      [t(:location), course.location.to_s.split("\n").join(", ")],
      [t(:dates), course.dates.map(&:duration).join(", ")],
      [t(:participant_count), course.participant_count],
      [t(:teamer_count), course.teamer_count]
    ]
  end

  def course
    model
  end

  def course_number_link
    {content: "<link href=\"#{course_url}\"><color rgb=\"#0000EE\">#{course.number}</color></link>",
     inline_format: true}
  end

  def course_url
    defaults = Rails.configuration.action_mailer.default_url_options
    Rails.application.routes.url_helpers.group_event_url(
      group_id: course.group_ids.first,
      id: course.id,
      host: defaults[:host],
      protocol: defaults[:protocol]
    )
  end

  def t(key, options = {})
    I18n.t("participations.participant_list.#{key}", **options)
  end
end
