# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::ParticipantList
  FONT_SIZE = 8
  LOGO_WIDTH = 170
  LOGO_HEIGHT = 71

  delegate :bounds, :cursor, to: :pdf

  attr_reader :course, :kind, :host

  def initialize(course, kind, host)
    @course = course
    @kind = kind
    @host = host
  end

  def render
    pdf.font_size(for_leaders? ? FONT_SIZE - 2 : FONT_SIZE)
    I18n.with_locale(course_locale) do
      [Sections::Logo, Sections::Header, Sections::Table].collect do |section|
        section.new(pdf, course, kind: kind, host: host).render
      end
    end
    pdf.render
  end

  def pdf
    @pdf ||= Export::Pdf::Document.new(page_layout: :landscape, margin: [1.5.cm]).pdf
  end

  def filename
    parts = [t(:file_name_prefix)]
    parts << leader_type_file_prefix
    parts << person.full_name.parameterize(separator: "_", preserve_case: true)
    parts << Time.zone.now.strftime("%Y_%m_%d_%H%M")
    [parts.join("_"), :pdf].join(".")
  end

  private

  def course_locale
    {
      de: :de,
      de_fr: :de,
      fr: :fr,
      it: :it
    }[course.language.to_sym] || :de
  end

  def for_leaders?
    @kind == "for_leaders"
  end

  def t(key)
    I18n.t("participations.participant_list.#{key}")
  end
end
