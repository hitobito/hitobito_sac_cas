# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::Event::Participations::CourseDataList do
  let(:group) { groups(:bluemlisalp) }
  let(:list) { event_participations(:top_mitglied, :top_familienmitglied) }

  subject(:tabular) { described_class.new(list, group) }

  its(:model_class) { is_expected.to eq Event::Participation }
  its(:row_class) { is_expected.to eq Export::Tabular::Event::Participations::CourseDataRow }

  its(:attribute_labels) do
    is_expected.to eq(
      event_number: "Veranstaltungsnummer",
      event_dates_locations: "Kursortname",
      event_name: "Kursbezeichnung",
      event_first_date: "Anfangsdatum",
      event_last_date: "Enddatum",
      person_id: "Teilnehmernummer",
      person_gender: "Geschlecht",
      person_last_name: "Familienname",
      person_first_name: "Vorname",
      person_language_code: "Sprachcode",
      person_address: "Adresse",
      person_zip_code: "PLZ",
      person_town: "Ort",
      person_stammsektion: "Sektionsname",
      person_birthday: "Geburtsdatum",
      person_email: "Haupt-E-Mail"
    )
  end
end
