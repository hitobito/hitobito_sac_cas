# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::RolesImporter do
  let(:output) { double(puts: nil, print: nil) }
  let(:nav2_csv_fixture) { file_fixture("sac_imports_src/NAV2_fixture.csv") }
  let!(:importer) { described_class.new(output: output) }

  let(:report_file) { Rails.root.join("log", "sac_imports", "nav2-1_roles_people_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[navision_id navision_name group layer errors warnings] }
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
    csv_source_instance = SacImports::CsvSource.new(:NAV2)
    allow(csv_source_instance).to receive(:path).and_return(nav2_csv_fixture)
    importer.instance_variable_set(:@source_file, csv_source_instance)
  end

  it "creates csv report entries for roles with errors" do
    expected_output = Array.new(10) { [/\d+ \(.*\):/, " ✅\n"] }.flatten
    expected_output << "#{invalid_person_navision_id} ():"
    expected_output << " ❌ Bitte geben Sie einen Namen ein\n"

    expected_output.each do |output_line|
      expect(output).to receive(:print).with(output_line)
    end
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    importer.create

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(2)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report.second).to eq([invalid_person_navision_id, nil, "Bitte geben Sie einen Namen ein"])
  end
end
