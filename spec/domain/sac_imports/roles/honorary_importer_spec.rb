# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Roles::HonoraryImporter do
  let(:output) { double(puts: nil, print: nil) }
  let(:importer) { described_class.new(output: output, csv_source: csv_source, csv_report: csv_report_instance) }

  # csv report
  let(:report_file) { Rails.root.join("log", "sac_imports", "nav2-1_roles_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[navision_id person_name valid_from valid_until target_group target_role message warning error] }
  let(:csv_report_instance) { SacImports::CsvReport.new(:"nav2-1_roles", report_headers) }
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

  context "with NAV2 csv file fixture" do
    # csv source
    let(:nav2_csv_fixture) { file_fixture("sac_imports_src/NAV2_fixture.csv") }
    let(:csv_source) do
      csv_source_instance = SacImports::CsvSource.new(:NAV2)
      allow(csv_source_instance).to receive(:path).and_return(nav2_csv_fixture)
      csv_source_instance
    end

    let!(:cas_jaman) { Group::Sektion.create!(name: "CAS Jaman", parent: Group.root, foundation_year: 1942) }
    let(:jaman_mitglieder_group) { Group::SektionsMitglieder.find_by(parent: cas_jaman) }
    let!(:person5) { Fabricate(:person, id: 4200005, first_name: "Hans", last_name: "Muster") }
    let!(:person5_membership_role) do
      Group::SektionsMitglieder::Mitglied
        .create!(group: jaman_mitglieder_group, person: person5,
          start_on: "2010-01-01", end_on: "2024-12-31")
    end

    it "imports role from nav2 csv fixture file" do
      expect(output).to receive(:print).with("4200005 (Muster Hans): ✅ Honorary role created\n")

      importer.create

      expect(csv_report.size).to eq(2)
      expect(csv_report.first).to eq(report_headers)
      expect(csv_report[1]).to eq(["4200005",
        "Muster Hans",
        "2022-06-01",
        "2024-12-31",
        "Sektion > CAS Jaman > Mitglieder",
        "Ehrenmitglied",
        "Honorary role created", nil, nil])

      person5.reload
      expect(person5.roles.count).to eq(2)
      honorary_role = person5.roles.find_by(type: "Group::SektionsMitglieder::Ehrenmitglied")
      expect(honorary_role.group).to eq(jaman_mitglieder_group)
      expect(honorary_role.start_on).to eq(Date.new(2022, 6, 1))
      expect(honorary_role.end_on).to be_nil
    end
  end

  context "with mocked csv rows" do
    let(:mitglied) { people(:mitglied) }

    let(:row) do
      {
        navision_id: "600001",
        valid_from: "2022-06-21",
        valid_until: "2024-12-31",
        layer_type: "Sektion",
        group_level1: "SAC Blüemlisalp",
        group_level2: "Mitglieder",
        group_level3: nil,
        group_level4: nil,
        role: "Ehrenmitglied",
        role_description: nil,
        person_name: "Hillary Edmund",
        other: nil
      }
    end

    let(:rows) { [row].compact }

    let(:csv_source) do
      csv_source_instance = SacImports::CsvSource.new(:NAV2)
      allow(csv_source_instance).to receive(:rows).and_return(rows)
      csv_source_instance
    end

    context "creates honorary roles" do
      it "creates new honorary role and resets existing ones" do
        existing_role = Group::SektionsMitglieder::Ehrenmitglied.create!(person: mitglied, group: groups(:bluemlisalp_mitglieder))
        expect(output).to receive(:print).with("600001 (Hillary Edmund): ✅ Honorary role created\n")

        importer.create

        expect(csv_report.size).to eq(2)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["600001",
          "Hillary Edmund",
          "2022-06-21",
          "2024-12-31",
          "Sektion > SAC Blüemlisalp > Mitglieder",
          "Ehrenmitglied",
          "Honorary role created", nil, nil])

        mitglied.reload
        expect(mitglied.roles.count).to eq(3)
        honorary_role =
          Group::SektionsMitglieder::Ehrenmitglied.find_by(person: mitglied)
        expect(honorary_role.group).to eq(groups(:bluemlisalp_mitglieder))
        expect(Group::SektionsMitglieder::Ehrenmitglied.where(id: existing_role.id)).not_to exist
      end

      it "reports person not found" do
        row[:navision_id] = "42"

        expect(output).to receive(:print).with("42 (Hillary Edmund): ❌ Person not found in hitobito\n")

        importer.create

        expect(csv_report.size).to eq(2)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["42",
          "Hillary Edmund",
          "2022-06-21",
          "2024-12-31",
          "Sektion > SAC Blüemlisalp > Mitglieder",
          "Ehrenmitglied",
          nil, nil, "Person not found in hitobito"])
      end

      it "reports missing section/ortsguppe group" do
        row[:group_level1] = "SAC Unknown"

        expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ No Section/Ortsgruppe group found for 'SAC Unknown'\n")

        importer.create

        expect(csv_report.size).to eq(2)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["600001",
          "Hillary Edmund",
          "2022-06-21",
          "2024-12-31",
          "Sektion > SAC Unknown > Mitglieder",
          "Ehrenmitglied",
          nil, nil, "No Section/Ortsgruppe group found for 'SAC Unknown'"])
      end
    end
  end
end
