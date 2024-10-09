# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::QualificationsImporter do
  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }
  let(:output) { $stdout } # double(puts: nil, print: nil) }
  let(:report) { described_class.new(output: output) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "8_qualifications_2024-01-23-11:42.csv") }
  let(:report_headers) {
    %w[navision_id hitobito_person navision_qualification_active
      navision_start_at navision_finish_at navision_qualification_kind warnings errors]
  }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  before do
    File.delete(report_file) if File.exist?(report_file)
    stub_const("SacImports::CsvSource::SOURCE_DIR", sac_imports_src)

    10.times do |i|
      Fabricate(:person, id: 4200000 + i)
    end
    QualificationKind.create!(label: "SAC Tourenleiter*in 1 Winter")
    QualificationKind.create!(label: "SAC Tourenleiter*in 1 Sommer")
    QualificationKind.create!(label: "SAC Tourenleiter*in Bergwandern")
    QualificationKind.create!(label: "Wanderleiter*in bis T4")
    QualificationKind.create!(label: "SAC Tourenleiter - Aspirant*in")
    QualificationKind.create!(label: "SAC Tourenleiter*in Sportklettern")
  end

  it "creates report for members in source file" do
    expected_output = Array.new(10) { [/\d+ \(.*\):/, " ✅\n"] }.flatten
    expected_output << "4200010 (Leiter*in Kinderbergsteigen):" << " ❌ Person couldn't be found, Qualification kind couldn't be found\n"
    expected_output << Array.new(5) { [/\d+ \(.*\):/, " ✅\n"] }.flatten
    expected_output << "4200005 (Wanderleiter*in Kantonal + SBV):" << " ❌ Qualification kind couldn't be found, Qualification kind muss ausgefüllt werden\n"
    expected_output << "4200006 (Schneeschuhleiter*in bis WT4):" << " ❌ Qualification kind couldn't be found, Qualification kind muss ausgefüllt werden\n"
    expected_output << Array.new(3) { [/\d+ \(.*\):/, " ✅\n"] }.flatten
    expected_output << "4200010 (SAC Tourenleiter - Aspirant*in):" << " ❌ Person couldn't be found\n"
    expected_output << /\d+ \(.*\):/ << " ✅\n"
    expected_output << "4200001 (SAC Tourenleiter*in 1 Winter Senioren):" << " ❌ Qualification kind couldn't be found, Qualification kind muss ausgefüllt werden\n"
    expected_output << Array.new(5) { [/\d+ \(.*\):/, " ✅\n"] }.flatten
    expected_output << "4200007 (Murmeltierdoktor*in):" << " ❌ Qualification kind couldn't be found, Qualification kind muss ausgefüllt werden\n"
    expected_output << Array.new(2) { [/\d+ \(.*\):/, " ✅\n"] }.flatten
    expected_output << "4200010 (SAC Tourenleiter*in Alpinwandern):" << " ❌ Person couldn't be found, Qualification kind couldn't be found\n"
    expected_output << Array.new(5) { [/\d+ \(.*\):/, " ✅\n"] }.flatten

    expected_output.flatten.each do |output_line|
      expect(output).to receive(:print).with(output_line)
    end
    expect(output).to receive(:puts).with("\n\n\nReport generated in 0.0 minutes.")
    expect(output).to receive(:puts).with("Thank you for flying with SAC Imports.")
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    travel_to DateTime.new(2024, 1, 23, 10, 42)

    expect { report.create }
      .to change { Qualification.count }.by(31)

    expect(Qualification.last.attributes).to include(
      "person_id" => 4200004,
      "qualification_kind_id" => QualificationKind.find_by(label: "SAC Tourenleiter*in 1 Winter").id,
      "start_at" => Date.new(2024, 2, 4),
      "finish_at" => Date.new(2030, 12, 31)
    )

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(10)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report.pluck(6).compact).to eq(["warnings", "Active in NAV3 but would be inactive by hitobito", "Active in NAV3 but would be inactive by hitobito"])

    File.delete(report_file)
    expect(File.exist?(report_file)).to be_falsey
  end
end
