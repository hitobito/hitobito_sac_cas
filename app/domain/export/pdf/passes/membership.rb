# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require_relative 'membership/person'
require_relative 'membership/footer'

module Export::Pdf::Passes
  class Membership

    def initialize(person)
      @person = person
    end

    def render
      sections.each do |section|
        section.render
      end
      pdf.render
    end

    def pdf
      @pdf ||= Prawn::Document.new(render_options)
    end

    def filename
      parts = [t(:file_name_prefix)]
      parts << Time.zone.now.year
      parts << @person.full_name.parameterize(separator: '_')
      [parts.join('-'), :pdf].join('.')
    end

    private

    def render_options
      @options.to_h.merge(
        page_size: 'A4',
        page_layout: :portrait,
        margin: [0, 0, 0, 0]
      )
    end

    def sections
      @sections ||=
        [Export::Pdf::Passes::Sections::Logo, Person, Footer].collect do |section|
          section.new(pdf, @person, {})
        end
    end

    def t(key)
      I18n.t("passes.membership.#{key}")
    end

  end
end
