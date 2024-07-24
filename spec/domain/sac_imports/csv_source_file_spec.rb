# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::CsvSourceFile do
  let(:source_file) { described_class.new(@source_name) }

  it "throws error if unavailable source file referenced" do
    @source_name = :NAV42
    expect do
      source_file
    end.to raise_error("Invalid source name: NAV42\navailable sources: #{SacImports::CsvSourceFile::AVAILABLE_SOURCES.map(&:to_s).join(', ')}")
  end

  it "throws error if requested source file does not exist" do
    @source_name = :NAV2
    expect(Dir)
      .to receive(:glob)
      .with("#{Rails.root.join("tmp", "sac_imports_src")}/NAV2_*.csv")
      .and_return([])

    expect do
      source_file.rows
    end.to raise_error("No source file NAV2_*.csv found in RAILS_CORE_ROOT/tmp/sac_imports_src/.")
  end

  it "converts csv content to hashes with key value pairs defined by header mapping" do
    @source_name = :NAV2
    expect(Dir)
      .to receive(:glob)
      .with("#{Rails.root.join("tmp", "sac_imports_src")}/NAV2_*.csv")
      .and_return([File.expand_path("../../../fixtures/files/sac_imports_src/NAV2_stammmitgliedschaften_2024-01-04.csv", __FILE__)])
    allow(Dir)
      .to receive(:glob)
      .and_call_original

    rows = source_file.rows
    expect(rows.count).to eq(2)
    expect(rows.first).to eq({ person_name: "Montana Andreas", navision_id: "1000", household_key: nil, group_navision_id: "1500", navision_membership_years: "44" })
    expect(rows.second).to eq({ person_name: "Hillary Edmund", navision_id: "600001", household_key: nil, group_navision_id: "1650", navision_membership_years: "9" })
  end
end
