# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::CsvSource do
  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }

  before do
    allow(Rails.root)
      .to receive(:join)
      .with("tmp", "sac_imports_src")
      .and_return(sac_imports_src)
  end

  let(:source_file) { described_class.new(@source_name) }

  it "throws error if unavailable source file referenced" do
    @source_name = :NAV42
    expect do
      source_file
    end.to raise_error("Invalid source name: NAV42\nAvailable sources: #{SacImports::CsvSource::AVAILABLE_SOURCES.map(&:to_s).join(", ")}")
  end

  it "throws error if requested source file does not exist" do
    @source_name = :NAV2
    expect(Dir)
      .to receive(:glob)
      .with(sac_imports_src.join("NAV2_*.csv").to_s)
      .and_return([])

    expect do
      source_file.rows
    end.to raise_error(/^No source file NAV2_\*\.csv found in.+$/)
  end

  it "converts csv content to hashes with key value pairs defined by header mapping" do
    @source_name = :NAV2
    rows = source_file.rows
    expect(rows.count).to eq(2)
    expect(rows.first).to eq({navision_name: "Montana Andreas", navision_id: "1000", household_key: nil, group_navision_id: "1500", navision_membership_years: "44"})
    expect(rows.second).to eq({navision_name: "Hillary Edmund", navision_id: "600001", household_key: nil, group_navision_id: "1650", navision_membership_years: "9"})
  end

  it "converts WSO21 content to hashes with key value pairs defined by header mapping" do
    @source_name = :WSO21
    rows = source_file.rows
    expect(rows.count).to eq(9)
    expect(rows.first).to eq({
      address: "Drosselweg 99b",
      address_care_of: nil,
      birthday: "16.11.1993",
      country: "CH",
      email: "example@example.com",
      email_verified: "1",
      first_name: "Assunta",
      gender: "HERR",
      language: "F",
      last_name: "Elliot",
      navision_id: "4200000",
      phone: "'79 123 45 67",
      phone_business: nil,
      postbox: nil,
      role_abonnent: "0",
      role_basiskonto: "0",
      role_gratisabonnent: "0",
      town: "Miège",
      wso2_legacy_password_hash: "YfVCNCik1IQnGrRNcxlsNpJl6rCKmOFb3wGISEB81l0=",
      # ggignore: secret
      wso2_legacy_password_salt: "xwQcHLXumdiO3O22lSX6Jw==",
      zip_code: "3972"
    })
  end
end
