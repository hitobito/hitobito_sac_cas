# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::MembershipYearsReport do
  let(:nav1_csv_fixture) { File.expand_path("../../../fixtures/files/sac_imports_src/NAV1_Kontakte_NAV-20240726.csv", __FILE__) }
  let(:output) { double(puts: nil, print: nil) }
  let(:report) { described_class.new(output: output) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "6_membership_years_report_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[navision_membership_number navision_name navision_membership_years hitobito_membership_years diff errors] }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }
  let!(:non_member) { Fabricate(:person, id: 513546) }
  let(:bluemlisalp_mitglieder) { groups(:bluemlisalp_mitglieder) }
  let!(:member) do
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
      group: bluemlisalp_mitglieder,
      person: Fabricate(:person, id: 513549),
      created_at: "2000-1-1")
  end
  let!(:member2) do
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
      group: bluemlisalp_mitglieder,
      person: Fabricate(:person, id: 513550),
      created_at: "2010-1-1")
  end

  before do
    File.delete(report_file) if File.exist?(report_file)
  end

  it "creates report for members in source file" do
    expected_output = Array.new(9) { [/Reading row .* .../, " processed.\n"] }.flatten

    expected_output.each do |output_line|
      expect(output).to receive(:print).with(output_line)
    end
    expect(output).to receive(:puts).with("Thank you for flying with SAC Imports.")
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    expect(Dir)
      .to receive(:glob)
      .with(Rails.root.join("tmp", "sac_imports_src", "NAV1_*.csv").to_s)
      .and_return([nav1_csv_fixture])

    travel_to DateTime.new(2024, 1, 23, 10, 42)

    report.create

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(10)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report.second).to eq(["513544", "Müller", "42", nil, nil, "Person not found in hitobito"])
    expect(csv_report.third).to eq(["513546", "Meier", "3", "0.0", "3.0", nil])
    expect(csv_report.fourth).to eq(["513549", "Schneider", "24", "24.0", "0.0", nil])
    expect(csv_report.fifth).to eq(["513550", "Weber", nil, "14.0", "-14.0", nil])

    File.delete(report_file)
    expect(File.exist?(report_file)).to be_falsey
  end
end
