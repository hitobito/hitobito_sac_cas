# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::CsvSource do
  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }

  let(:source_file) { described_class.new(@source_name, source_dir: sac_imports_src) }

  it "throws error if unavailable source file referenced" do
    @source_name = :NAV42
    expect do
      source_file
    end.to raise_error("Invalid source name: NAV42\nAvailable sources: #{SacImports::CsvSource::AVAILABLE_SOURCES.map(&:to_s).join(", ")}")
  end

  it "throws error if requested source file does not exist" do
    @source_name = :NAV2a
    expect(Dir)
      .to receive(:glob)
      .with(sac_imports_src.join("NAV2a_*.csv").to_s)
      .and_return([])

    expect do
      source_file.rows
    end.to raise_error(/^No source file NAV2a_\*\.csv found in.+$/)
  end

  it "converts csv content to hashes with key value pairs defined by header mapping" do
    @source_name = :NAV2b
    rows = source_file.rows
    expect(rows.count).to eq(5)
    expect(rows[2].to_h).to include({navision_id: "4200008",
                             valid_from: "2018-02-15",
                             valid_until: nil,
                             layer_type: "SAC/CAS",
                             group_level1: "Verbände & Organisationen",
                             group_level2: "Rettungsstationen",
                             group_level3: "Samedan",
                             group_level4: nil,
                             role: "Mitglied",
                             role_description: "Retter I",
                             person_name: "Bühler Christian"})
  end

  it "converts WSO21 content to hashes with key value pairs defined by header mapping" do
    @source_name = :WSO21
    rows = source_file.rows
    expect(rows.count).to eq(10)
    expect(rows.second.to_h).to include({
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

  it "applies additional regex value filter for rows" do
    @source_name = :NAV2a
    rows = source_file.rows(filter: {role: /^Mitglied \(Stammsektion\).+/})
    expect(rows.count).to eq(12)
  end

  it "converts NAV3 content to hashes with key value pairs defined by header mapping" do
    @source_name = :NAV3
    rows = source_file.rows
    expect(rows.count).to eq(38)
    expect(rows.first.to_h).to include({
      navision_id: "4200000",
      active: "1",
      start_at: "2022-06-26",
      finish_at: "2028-12-31",
      qualification_kind: "SAC Tourenleiter*in 1 Sommer"
    })
  end
end
