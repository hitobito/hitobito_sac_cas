# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::KeyDataSheet
  FONT_SIZE = 9

  def initialize(participation)
    @participation = participation
  end

  def render
    I18n.with_locale(course_locale) do
      pdf.font_size = FONT_SIZE
      sections.each do |section|
        section.render
      end
    end
    pdf.render
  end

  def pdf
    @pdf ||= Prawn::Document.new(render_options)
  end

  def filename
    parts = [t(:file_name_prefix)]
    parts << leader_type_file_prefix
    parts << person.full_name.parameterize(separator: "_", preserve_case: true)
    parts << Time.zone.now.strftime("%Y_%m_%d_%H%M")
    [parts.join("_"), :pdf].join(".")
  end

  private

  def render_options
    @options.to_h.merge(
      page_size: "A4",
      page_layout: :portrait,
      margin: [45, 45, 55, 70]
    )
  end

  def sections
    @sections ||=
      [Sections::Logo, Sections::Title, Sections::Table, Sections::Footer].collect do |section|
        section.new(pdf, @participation, {})
      end
  end

  def t(key)
    I18n.t("participations.key_data_sheet.#{key}")
  end

  def person
    @person ||= @participation.person
  end

  def event
    @event ||= @participation.event
  end

  def course_locale
    {
      de: :de,
      de_fr: :de,
      fr: :fr,
      it: :it
    }[event.language.to_sym] || :de
  end

  def leader_type_file_prefix
    if @participation.roles.any? { _1.is_a?(Event::Course::Role::Leader) }
      t(:leader_file_prefix)
    else
      t(:assistant_leader_file_prefix)
    end
  end
end
