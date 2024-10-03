# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Roles::MembershipsImporter do
  let(:output) { double(puts: nil, print: nil) }

  # csv source
  let(:nav2_csv_fixture) { file_fixture("sac_imports_src/NAV2_fixture.csv") }
  let(:csv_source) do
    csv_source_instance = SacImports::CsvSource.new(:NAV2)
    allow(csv_source_instance).to receive(:path).and_return(nav2_csv_fixture)
    csv_source_instance
  end

  # csv report
  let(:report_file) { Rails.root.join("log", "sac_imports", "nav2-1_roles_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[navision_id person_name valid_from valid_until target_group target_role errors warnings] }
  let(:csv_report_instance) { SacImports::CsvReport.new(:"nav2-1_roles", report_headers) }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  let(:importer) { described_class.new(output: output, csv_source: csv_source, csv_report: csv_report_instance) }

  around do |example|
    # make sure there's no csv report from previous run
    File.delete(report_file) if File.exist?(report_file)
    travel_to(DateTime.new(2024, 1, 23, 10, 42))

    example.run

    File.delete(report_file) if File.exist?(report_file)
    expect(File.exist?(report_file)).to be_falsey
    travel_back
  end

  it "reports people not found if they do not exist by navision id" do
    importer.create

    expect(csv_report.size).to eq(13)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report.second).to eq(["4200000",
                                     "Nachname 1 Vorname 1",
                                     "2014-10-06",
                                     "2022-12-31",
                                     "Sektion > CAS La Chaux-de-Fonds > Mitglieder",
                                     "Mitglied (Stammsektion) (Jugend)",
                                     "Person not found in hitobito", nil])
    expect(csv_report.third).to eq(["4200000",
                                    "Nachname 1 Vorname 1",
                                     "2023-01-01",
                                     "2024-12-31",
                                    "Sektion > CAS La Chaux-de-Fonds > Mitglieder",
                                    "Mitglied (Stammsektion) (Einzel)",
                                    "A previous role could not be imported for this person, skipping", nil])
  end

  it "Creates or updates membership roles and sets family main person" do
    # it adds error and report if person cannot be found
  end
end
