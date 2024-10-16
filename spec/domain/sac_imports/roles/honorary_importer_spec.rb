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

  let!(:cas_jaman) { Group::Sektion.create!(name: "CAS Jaman", parent: Group.root, foundation_year: 1942) }
  let(:jaman_mitglieder_group) { Group::SektionsMitglieder.find_by(parent: cas_jaman) }

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
      it "creates new honorary role" do
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
      end

      #it "creates addtional membership role in ortsgruppe" do
        #roles(:mitglied_zweitsektion).destroy!
        #row[:group_level1] = "SAC Blüemlisalp"
        #row[:group_level2] = "SAC Blüemlisalp Ausserberg"
        #row[:group_level3] = "Mitglieder"

        #expect(output).to receive(:print).with("600001 (Hillary Edmund): ✅ Additional Membership role created\n")

        #importer.create

        #expect(csv_report.size).to eq(2)
        #expect(csv_report.first).to eq(report_headers)
        #expect(csv_report.second).to eq(["600001",
          #"Hillary Edmund",
          #"2017-06-21",
          #"2024-12-31",
          #"Sektion > SAC Blüemlisalp > SAC Blüemlisalp Ausserberg > Mitglieder",
          #"Mitglied (Zusatzsektion) (Einzel)",
          #"Additional Membership role created", nil, nil])

        #mitglied.reload
        #expect(mitglied.roles.count).to eq(2)
        #additional_membership_role =
          #Group::SektionsMitglieder::MitgliedZusatzsektion
          #.find_by(person: mitglied,
                   #group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder))
        #expect(additional_membership_role.beitragskategorie).to eq("adult")
        #expect(mitglied.sac_family_main_person).to eq(false)
        #expect(mitglied.primary_group).to eq(groups(:bluemlisalp_mitglieder))
      #end

      #it "reports person not found" do
        #row[:navision_id] = "42"

        #expect(output).to receive(:print).with("42 (Hillary Edmund): ❌ Person not found in hitobito\n")

        #importer.create

        #expect(csv_report.size).to eq(2)
        #expect(csv_report.first).to eq(report_headers)
        #expect(csv_report.second).to eq(["42",
          #"Hillary Edmund",
          #"2017-06-21",
          #"2024-12-31",
          #"Sektion > CAS Moléson > Mitglieder",
          #"Mitglied (Zusatzsektion) (Einzel)",
          #nil, nil, "Person not found in hitobito"])
      #end

      #it "reports if valid_from is after valid_until and skips further role creation for this person" do
        #second_row = row.dup
        #row[:valid_until] = "1992-01-01" # set valid_until before valid_from
        #rows << second_row

        #expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ valid_from (GültigAb) cannot be before valid_until (GültigBis)\n")
        #expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ A previous role could not be imported for this person, skipping\n")

        #importer.create

        #expect(csv_report.size).to eq(3)
        #expect(csv_report.first).to eq(report_headers)
        #expect(csv_report.second).to eq(["600001",
          #"Hillary Edmund",
          #"2017-06-21",
          #"1992-01-01",
          #"Sektion > CAS Moléson > Mitglieder",
          #"Mitglied (Zusatzsektion) (Einzel)",
          #nil, nil, "valid_from (GültigAb) cannot be before valid_until (GültigBis)"])
      #end

      #it "reports missing section/ortsguppe group" do
        #row[:group_level1] = "SAC Unknown"

        #expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ No Section/Ortsgruppe group found for 'SAC Unknown'\n")

        #importer.create

        #expect(csv_report.size).to eq(2)
        #expect(csv_report.first).to eq(report_headers)
        #expect(csv_report.second).to eq(["600001",
          #"Hillary Edmund",
          #"2017-06-21",
          #"2024-12-31",
          #"Sektion > SAC Unknown > Mitglieder",
          #"Mitglied (Zusatzsektion) (Einzel)",
          #nil, nil, "No Section/Ortsgruppe group found for 'SAC Unknown'"])
      #end

      #it "reports unknown beitragskategorie" do
        #row[:role] = "Mitglied (Zusatzsektion) (ERROR)"

        #expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ Invalid Beitragskategorie in 'Mitglied (Zusatzsektion) (ERROR)'\n")

        #importer.create
      #end

      #it "reports if additional membership role cannot be created" do
        #role_instance = Role.new
        #expect(Group::SektionsMitglieder::MitgliedZusatzsektion).to receive(:new).and_return(role_instance)

        #expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ Hitobito Role: Person muss ausgefüllt werden, Group muss ausgefüllt werden, Rolle muss ausgefüllt werden\n")

        #importer.create
      #end
    end
  end
end
