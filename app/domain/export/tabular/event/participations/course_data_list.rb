# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::Event::Participations
  class CourseDataList < Export::Tabular::Base
    self.model_class = ::Event::Participation
    self.row_class = CourseDataRow

    # rubocop:todo Metrics/MethodLength
    def build_attribute_labels # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/MethodLength
      {}.tap do |labels|
        labels[:event_number] = "Veranstaltungsnummer"
        labels[:event_dates_locations] = "Kursortname"
        labels[:event_name] = "Kursbezeichnung"
        labels[:event_first_date] = "Anfangsdatum"
        labels[:event_last_date] = "Enddatum"
        labels[:person_id] = "Teilnehmernummer"
        labels[:person_gender] = "Geschlecht"
        labels[:person_last_name] = "Familienname"
        labels[:person_first_name] = "Vorname"
        labels[:person_language_code] = "Sprachcode"
        labels[:person_address] = "Adresse"
        labels[:person_zip_code] = "PLZ"
        labels[:person_town] = "Ort"
        labels[:person_stammsektion] = "Sektionsname"
        labels[:person_birthday] = "Geburtsdatum"
        labels[:person_email] = "Haupt-E-Mail"
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
