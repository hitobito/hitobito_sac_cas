# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::PeopleImporter do
  let(:nav1_csv_fixture) { File.expand_path("../../../fixtures/files/sac_imports_src/NAV1_Kontakte_20240822_testdata.csv", __FILE__) }
  let(:output) { double(puts: nil, print: nil) }
  let(:report) { described_class.new(output: output) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "1_people_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[navision_membership_number navision_name errors] }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  before do
    File.delete(report_file) if File.exist?(report_file)
  end

  it "creates report for members in source file" do
    expected_output = Array.new(11) { [/\d+ \(.*\):/, " ✅\n"] }.flatten

    expected_output.each do |output_line|
      expect(output).to receive(:print).with(output_line)
    end
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    expect(Dir)
      .to receive(:glob)
      .with(Rails.root.join("tmp", "sac_imports_src", "NAV1_*.csv").to_s)
      .and_return([nav1_csv_fixture])

    travel_to DateTime.new(2024, 1, 23, 10, 42)

    report.create

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(2)
    expect(csv_report.first).to eq(report_headers)

    File.delete(report_file)
    expect(File.exist?(report_file)).to be_falsey
  end
end
