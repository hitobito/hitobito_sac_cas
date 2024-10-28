# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::MembershipYearsReport do
  let(:output) { double(puts: nil, print: nil) }
  let(:nav1_csv_fixture) { file_fixture("sac_imports_src/NAV1_fixture.csv") }
  let!(:report) { described_class.new(output: output) }

  let!(:non_member) { Fabricate(:person, id: 4200002) }
  let(:bluemlisalp_mitglieder) { groups(:bluemlisalp_mitglieder) }
  let!(:member) do
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
      group: bluemlisalp_mitglieder,
      person: Fabricate(:person, id: 4200000),
      start_on: "2000-1-1")
  end
  let!(:member2) do
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
      group: bluemlisalp_mitglieder,
      person: Fabricate(:person, id: 4200001),
      start_on: "2010-1-1")
  end
  let!(:member4) do
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
      group: bluemlisalp_mitglieder,
      person: Fabricate(:person, id: 4200003),
      start_on: "2015-12-1")
  end

  let(:report_file) { Rails.root.join("log", "sac_imports", "nav1-2_membership_years_report_2024-01-23-1142.csv") }
  let(:report_headers) { %w[navision_membership_number navision_name navision_membership_years hitobito_membership_years diff errors] }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  around do |example|
    # make sure there's no csv report from previous run
    File.delete(report_file) if File.exist?(report_file)
    travel_to(DateTime.new(2024, 1, 23, 10, 42))

    example.run

    File.delete(report_file) if File.exist?(report_file)
    expect(File.exist?(report_file)).to be_falsey
    travel_back
  end

  before do
    # Mock the file loading behavior in CSVImporter
    csv_source_instance = SacImports::CsvSource.new(:NAV1)
    allow(csv_source_instance).to receive(:path).and_return(nav1_csv_fixture)
    report.instance_variable_set(:@source_file, csv_source_instance)
  end

  it "creates report for members in source file" do
    expected_output = Array.new(9) { [/Reading row .* .../, " processed.\n"] }.flatten

    expected_output.each do |output_line|
      expect(output).to receive(:print).with(output_line)
    end
    expect(output).to receive(:puts).with("Thank you for flying with SAC Imports.")
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    report.create

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(12)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report.second).to eq(["4200000", "Nachname 1 Vorname 1", "35", "24.0", "11.0", nil])
    expect(csv_report.third).to eq(["4200001", "Maurer Johannes", "14", "14.0", "0.0", nil])
    expect(csv_report.fourth).to eq(["4200002", "Potter Harry", nil, "0.0", "0.0", nil])
    expect(csv_report.fifth).to eq(["4200003", "Cochet Frederique", "8", "8.0", "0.0", nil])
    expect(csv_report.last).to eq(["4200010", nil, "2", nil, nil, "Person not found in hitobito"])

    File.delete(report_file)
    expect(File.exist?(report_file)).to be_falsey
  end
end
