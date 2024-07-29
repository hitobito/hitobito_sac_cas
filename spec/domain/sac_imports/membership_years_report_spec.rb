# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::MembershipYearsReport do
  let(:nav2_csv_fixture) { File.expand_path("../../../fixtures/files/sac_imports_src/NAV2_stammmitgliedschaften_2024-01-04.csv", __FILE__) }
  let(:report) { described_class.new }
  let(:report_file) { Rails.root.join("log", "sac_imports", "membership_years_report_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[membership_number person_name navision_membership_years hitobito_membership_years diff errors] }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  it "creates report for members in source file" do
    expect(Dir)
      .to receive(:glob)
      .with(Rails.root.join("tmp", "sac_imports_src", "NAV2_*.csv").to_s)
      .and_return([nav2_csv_fixture])

    travel_to DateTime.new(2024, 1, 23, 10, 42)

    report.create

    expect(File.exist?(report_file)).to be_truthy
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report.second).to eq(["1000", "Montana Andreas", "44", nil, nil, "Person not found in hitobito"])
    expect(csv_report.third).to eq(["600001", "Hillary Edmund", "9", "1", "8", nil])

    File.delete(report_file)
    expect(File.exist?(report_file)).to be_falsey
  end
end
