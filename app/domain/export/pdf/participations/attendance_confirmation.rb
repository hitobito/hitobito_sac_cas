# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::AttendanceConfirmation
  # Measured from the SAC template PDF
  FONT = "Helvetica"
  FONT_SIZE = 10
  LEADING = 1.45
  MARGIN = [1.5.cm, 2.cm, 2.5.cm, 2.6.cm].freeze

  delegate :event, :person, to: :@participation

  def initialize(participation)
    @participation = participation
  end

  def render
    I18n.with_locale(locale) do
      pdf.font FONT
      pdf.font_size = FONT_SIZE
      pdf.default_leading = LEADING
      sections.each(&:render)
    end
    pdf.render
  end

  def filename
    parts = [I18n.t("participations.attendance_confirmation.file_name_prefix", locale:)]
    parts << event.name.parameterize(separator: "_", preserve_case: true)
    parts << person.full_name.parameterize(separator: "_", preserve_case: true)
    [parts.join("_"), :pdf].join(".")
  end

  private

  def locale
    language = if event.language == "de_fr"
      person.language.presence_in(%w[de fr])
    else
      event.language
    end
    (language.presence || :de).to_sym
  end

  def pdf
    @pdf ||= Export::Pdf::Document.new(margin: MARGIN).pdf
  end

  def sections
    [Sections::Header, Sections::Address, Sections::Content, Sections::Footer].map do |section|
      section.new(pdf, @participation, {})
    end
  end
end
