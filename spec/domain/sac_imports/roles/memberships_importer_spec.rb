# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Roles::MembershipsImporter do
  let(:output) { double(puts: nil, print: nil) }

  # csv source
  let(:nav2_csv_fixture) { file_fixture("sac_imports_src/NAV2_fixture.csv") }
  let(:csv_source) do
    csv_source_instance = SacImports::CsvSource.new(:NAV2)
    allow(csv_source_instance).to receive(:path).and_return(nav2_csv_fixture)
    csv_source_instance
  end

  # csv report
  let(:report_file) { Rails.root.join("log", "sac_imports", "nav2-1_roles_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[navision_id person_name valid_from valid_until target_group target_role message warning error] }
  let(:csv_report_instance) { SacImports::CsvReport.new(:"nav2-1_roles", report_headers) }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  let(:importer) { described_class.new(output: output, csv_source: csv_source, csv_report: csv_report_instance) }

  let!(:person2) { Fabricate(:person, id: 4200002, first_name: "Harry", last_name: "Potter") }
  let!(:person2_membership_role) do
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
              person: person2,
              created_at: DateTime.new(2010, 1, 1),
              delete_on: DateTime.new(2024, 12, 31),
              group: groups(:bluemlisalp_mitglieder))
  end
  let!(:person2_additional_membership_role) do
    Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.name.to_sym,
              person: person2,
              created_at: DateTime.new(2018, 1, 1),
              delete_on: DateTime.new(2024, 12, 31),
              group: groups(:matterhorn_mitglieder))
  end
  let!(:person2_inactive_membership_role) do
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
              person: person2,
              created_at: DateTime.new(2000, 1, 1),
              delete_on: DateTime.new(2008, 12, 31),
              group: groups(:bluemlisalp_mitglieder))
  end

  around do |example|
    # make sure there's no csv report from previous run
    File.delete(report_file) if File.exist?(report_file)
    travel_to(DateTime.new(2024, 1, 23, 10, 42))

    example.run

    File.delete(report_file) if File.exist?(report_file)
    expect(File.exist?(report_file)).to be_falsey
    travel_back
  end

  it "reports people not found if they do not exist by navision id" do
    expected_output = []
    expected_output << "4200000 (Nachname 1 Vorname 1): ❌ Person not found in hitobito\n"
    expected_output << "4200000 (Nachname 1 Vorname 1): ❌ A previous role could not be imported for this person, skipping\n"

    expected_output.each do |output_line|
      expect(output).to receive(:print).with(output_line)
    end

    importer.create

    #expect(csv_report.size).to eq(13)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report.second).to eq(["4200000",
                                     "Nachname 1 Vorname 1",
                                     "2014-10-06",
                                     "2022-12-31",
                                     "Sektion > CAS La Chaux-de-Fonds > Mitglieder",
                                     "Mitglied (Stammsektion) (Jugend)",
                                     nil, nil, "Person not found in hitobito"])
    expect(csv_report.third).to eq(["4200000",
                                    "Nachname 1 Vorname 1",
                                    "2023-01-01",
                                    "2024-12-31",
                                    "Sektion > CAS La Chaux-de-Fonds > Mitglieder",
                                    "Mitglied (Stammsektion) (Einzel)",
                                    nil, nil, "A previous role could not be imported for this person, skipping"])
  end

  it "creates/resets membership roles and sets family main person" do
    importer.create

    person2_membership_role_ids = [person2_membership_role.id,
                                   person2_additional_membership_role.id,
                                   person2_inactive_membership_role.id]
    expect(Role.with_deleted.where(id: person2_membership_role_ids)).not_to exist

    person2_new_membership_role = person2.roles.first
  end
end
