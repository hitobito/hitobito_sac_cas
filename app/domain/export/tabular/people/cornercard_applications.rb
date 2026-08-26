# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Export::Tabular::People
  class CornercardApplications
    def initialize(cornercard_uploads)
      @uploads = cornercard_uploads.includes(:person)
    end

    def to_xlsx
      package = Axlsx::Package.new
      workbook = package.workbook
      workbook.add_worksheet(name: "Cornèrcard Anträge") do |sheet|
        sheet.add_row(headers)
        @uploads.each do |upload|
          sheet.add_row(row_for(upload))
        end
      end
      package.to_stream
    end

    private

    def headers
      [
        "Anrede",
        "Vorname",
        "Nachname",
        "Strasse",
        "Hausnummer",
        "PLZ",
        "Ort",
        "Land",
        "E-Mail",
        "Telefon",
        "Geburtsdatum",
        "Geschlecht",
        "Antragsdatum"
      ]
    end

    def row_for(upload)
      p = upload.person
      row_data(p) + [I18n.l(upload.created_at.to_date)]
    end

    def row_data(person)
      [
        gender_label(person),
        person.first_name,
        person.last_name,
        person.street,
        person.housenumber,
        person.zip_code,
        person.town,
        person.country,
        person.email,
        person.phone_numbers.first&.number,
        person.birthday ? I18n.l(person.birthday) : nil,
        person.gender
      ]
    end

    def gender_label(person)
      if person.gender == "m"
        "Herr"
      else
        "Frau"
      end
    end
  end
end
