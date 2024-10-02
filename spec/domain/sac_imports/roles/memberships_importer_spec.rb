# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Roles::MembershipsImporter do
  let(:output) { double(puts: nil, print: nil) }

  let(:importer) { described_class.new(output: output) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "nav2-1_roles_people_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[navision_id navision_name group layer errors warnings] }

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

  it "reports people not found if they do not exist by navision id" do
  end

  it "Creates or updates membership roles and sets family main person" do
    # it adds error and report if person cannot be found
  end
end
