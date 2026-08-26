# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::Tabular::People::CornercardApplications do
  let(:person) do
    Person.create!(
      first_name: "Max",
      last_name: "Muster",
      email: "max@example.com",
      street: "Musterplatz",
      housenumber: "42",
      zip_code: "4002",
      town: "Basel",
      country: "CH",
      birthday: Date.new(1990, 1, 15),
      gender: "m"
    )
  end

  let(:phone_number) { person.phone_numbers.create!(number: "+41 79 123 45 67", label: "mobile") }

  let(:upload) do
    person.create_cornercard_upload!
  end

  describe "#to_xlsx" do
    it "generates valid xlsx with correct data" do
      phone_number # ensure it exists
      exporter = described_class.new(CornercardUpload.all)
      xlsx_data = exporter.to_xlsx

      expect(xlsx_data).to be_present
      expect(xlsx_data).to be_a(StringIO)
    end
  end

  describe "#headers" do
    it "returns all required column headers" do
      exporter = described_class.new(CornercardUpload.all)
      headers = exporter.send(:headers)

      expect(headers).to include(
        "Vorname", "Nachname", "Strasse", "Hausnummer",
        "PLZ", "Ort", "E-Mail", "Geburtsdatum", "Geschlecht", "Antragsdatum"
      )
    end
  end

  describe "#row_for" do
    it "returns correct row data" do
      phone_number # ensure it exists
      exporter = described_class.new(CornercardUpload.all)
      row = exporter.send(:row_for, upload)

      expect(row).to include("Herr", "Max", "Muster", "Musterplatz", "42", "4002", "Basel", "CH", "max@example.com")
    end

    it "maps gender m to Herr" do
      exporter = described_class.new(CornercardUpload.all)
      row = exporter.send(:row_for, upload)

      expect(row.first).to eq("Herr")
    end

    it "maps gender w to Frau" do
      person.update!(gender: "w")
      exporter = described_class.new(CornercardUpload.all)
      row = exporter.send(:row_for, upload)

      expect(row.first).to eq("Frau")
    end
  end
end
