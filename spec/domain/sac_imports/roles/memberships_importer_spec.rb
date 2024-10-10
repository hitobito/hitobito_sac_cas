# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Roles::MembershipsImporter do
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

    let!(:navision_import_group) { Group::ExterneKontakte.create!(name: "Navision Import", parent: Group.root) }

    let!(:person1) { Fabricate(:person, id: 4200001, first_name: "Johannes", last_name: "Maurer") }
    let!(:person1_navision_import_role) { Fabricate(Group::ExterneKontakte::Kontakt.name.to_sym, person: person1, group: navision_import_group) }
    let!(:sac_chaux_de_fonds) { Group::Sektion.create!(name: "CAS La Chaux-de-Fonds", parent: Group.root, foundation_year: 1942) }

    it "imports role from nav2 csv fixture file" do
      expected_output = []
      expected_output << "4200000 (Nachname 1 Vorname 1): ❌ Person not found in hitobito\n"
      expected_output << "4200000 (Nachname 1 Vorname 1): ❌ A previous role could not be imported for this person, skipping\n"
      expected_output << "4200003 (Cochet Frederique): ❌ Person not found in hitobito\n"
      expected_output << "4200004 (Alder John): ❌ Person not found in hitobito\n"
      2.times { expected_output << "4200004 (Alder John): ❌ A previous role could not be imported for this person, skipping\n" }
      expected_output << "4200005 (Muster Hans): ❌ Person not found in hitobito\n"
      expected_output << "4200006 (Buri Max): ❌ Person not found in hitobito\n"
      expected_output << "4200008 (Bühler Christian): ❌ Person not found in hitobito\n"
      expected_output << "4200001 (Maurer Johannes): ✅ Membership role created\n"

      expected_output.each do |output_line|
        expect(output).to receive(:print).with(output_line)
      end

      importer.create

      expect(csv_report.size).to eq(13)
      expect(csv_report.first).to eq(report_headers)
      expect(csv_report[1]).to eq(["4200000",
        "Nachname 1 Vorname 1",
        "2014-10-06",
        "2022-12-31",
        "Sektion > CAS La Chaux-de-Fonds > Mitglieder",
        "Mitglied (Stammsektion) (Jugend)",
        nil, nil, "Person not found in hitobito"])
      expect(csv_report[2]).to eq(["4200000",
        "Nachname 1 Vorname 1",
        "2023-01-01",
        "2024-12-31",
        "Sektion > CAS La Chaux-de-Fonds > Mitglieder",
        "Mitglied (Stammsektion) (Einzel)",
        nil, nil, "A previous role could not be imported for this person, skipping"])
      expect(csv_report[3]).to eq(["4200001",
        "Maurer Johannes",
        "2014-10-06",
        "2018-06-06",
        "Sektion > CAS La Chaux-de-Fonds > Mitglieder",
        "Mitglied (Stammsektion) (Einzel)",
        "Membership role created", nil, nil])
      expect(csv_report[4]).to eq(["4200001",
        "Maurer Johannes",
        "2018-06-07",
        "2024-12-31",
        "Sektion > CAS La Chaux-de-Fonds > Mitglieder",
        "Mitglied (Stammsektion) (Frei Fam)",
        "Membership role created", nil, nil])
    end
  end

  context "with mocked csv rows" do
    let(:mitglied) { people(:mitglied) }
    let(:active_membership_role) { mitglied.roles.first }
    let(:inactive_membership_role) { mitglied.roles.deleted.first }

    let(:row) do
      {
        navision_id: "600001",
        valid_from: "2000-06-21",
        valid_until: "2024-12-31",
        layer_type: "Sektion",
        group_level1: "SAC Blüemlisalp",
        group_level2: "Mitglieder",
        group_level3: nil,
        group_level4: nil,
        role: "Mitglied (Stammsektion) (Einzel)",
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

    context "creates/resets membership roles" do
      it "clears existing membership roles and creates new membership role" do
        existing_roles = [roles(:mitglied), roles(:mitglied_zweitsektion)]
        expect(output).to receive(:print).with("600001 (Hillary Edmund): ✅ Membership role created\n")
        expect(existing_roles).to all(be_persisted)

        importer.create

        expect(csv_report.size).to eq(2)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["600001",
          "Hillary Edmund",
          "2000-06-21",
          "2024-12-31",
          "Sektion > SAC Blüemlisalp > Mitglieder",
          "Mitglied (Stammsektion) (Einzel)",
          "Membership role created", nil, nil])

        mitglied.reload
        expect(mitglied.roles.count).to eq(1)
        expect(active_membership_role.beitragskategorie).to eq("adult")
        expect(active_membership_role).to be_a(Group::SektionsMitglieder::Mitglied)
        expect(active_membership_role.group.parent.name).to eq("SAC Blüemlisalp")
        expect(mitglied.sac_family_main_person).to eq(false)

        existing_roles.each do |role|
          expect(Role.where(id: role.id)).not_to exist
        end
      end

      it "reports person not found" do
        row[:navision_id] = "42"

        expect(output).to receive(:print).with("42 (Hillary Edmund): ❌ Person not found in hitobito\n")

        importer.create

        expect(csv_report.size).to eq(2)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["42",
          "Hillary Edmund",
          "2000-06-21",
          "2024-12-31",
          "Sektion > SAC Blüemlisalp > Mitglieder",
          "Mitglied (Stammsektion) (Einzel)",
          nil, nil, "Person not found in hitobito"])
      end

      it "reports if valid_from is after valid_until and skips further role creation for this person" do
        second_row = row.dup
        row[:valid_until] = "1992-01-01" # set valid_until before valid_from
        rows << second_row

        expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ valid_from (GültigAb) cannot be before valid_until (GültigBis)\n")
        expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ A previous role could not be imported for this person, skipping\n")

        importer.create

        expect(csv_report.size).to eq(3)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["600001",
          "Hillary Edmund",
          "2000-06-21",
          "1992-01-01",
          "Sektion > SAC Blüemlisalp > Mitglieder",
          "Mitglied (Stammsektion) (Einzel)",
          nil, nil, "valid_from (GültigAb) cannot be before valid_until (GültigBis)"])
      end

      it "reports missing section/ortsguppe group" do
        row[:group_level1] = "SAC Unknown"

        expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ No Section/Ortsgruppe group found for 'SAC Unknown'\n")

        importer.create

        expect(csv_report.size).to eq(2)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["600001",
          "Hillary Edmund",
          "2000-06-21",
          "2024-12-31",
          "Sektion > SAC Unknown > Mitglieder",
          "Mitglied (Stammsektion) (Einzel)",
          nil, nil, "No Section/Ortsgruppe group found for 'SAC Unknown'"])
      end

      it "assings sac section members group as primary group" do
        row[:group_level1] = "SAC Matterhorn"

        expect(output).to receive(:print).with("600001 (Hillary Edmund): ✅ Membership role created\n")

        importer.create

        expect(csv_report.size).to eq(2)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["600001",
          "Hillary Edmund",
          "2000-06-21",
          "2024-12-31",
          "Sektion > SAC Matterhorn > Mitglieder",
          "Mitglied (Stammsektion) (Einzel)",
          "Membership role created", nil, nil])

        mitglied.reload
        expect(mitglied.primary_group).to eq(groups(:matterhorn_mitglieder))
      end

      it "reports unknown beitragskategorie" do
        row[:role] = "Mitglied (Stammsektion) (ERROR)"

        expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ Invalid Beitragskategorie in 'Mitglied (Stammsektion) (ERROR)'\n")

        importer.create
      end

      it "reports if membership role cannot be created" do
        role_instance = Role.new
        expect(Group::SektionsMitglieder::Mitglied).to receive(:new).and_return(role_instance)

        expect(output).to receive(:print).with("600001 (Hillary Edmund): ❌ Hitobito Role: Person muss ausgefüllt werden, Group muss ausgefüllt werden, Rolle muss ausgefüllt werden\n")

        importer.create
      end
    end

    context "family main person" do
      before do
        row[:role] = "Mitglied (Stammsektion) (Familie)"
      end

      it "creates active family role and sets sac_family_main_person to true" do
        importer.create

        expect(csv_report.size).to eq(2)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["600001",
          "Hillary Edmund",
          "2000-06-21",
          "2024-12-31",
          "Sektion > SAC Blüemlisalp > Mitglieder",
          "Mitglied (Stammsektion) (Familie)",
          "Membership role created", nil, nil])
        mitglied.reload
        expect(mitglied.roles.count).to eq(1)
        expect(active_membership_role.beitragskategorie).to eq("family")
        expect(active_membership_role).to be_a(Group::SektionsMitglieder::Mitglied)
        expect(mitglied.sac_family_main_person).to eq(true)
      end

      it "creates inactive family role and sets sac_family_main_person to false" do
        row[:valid_until] = "2023-12-31"

        importer.create

        expect(csv_report.size).to eq(2)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.second).to eq(["600001",
          "Hillary Edmund",
          "2000-06-21",
          "2023-12-31",
          "Sektion > SAC Blüemlisalp > Mitglieder",
          "Mitglied (Stammsektion) (Familie)",
          "Membership role created", nil, nil])

        mitglied.reload
        expect(mitglied.roles.count).to eq(0)
        expect(mitglied.roles.deleted.count).to eq(1)
        expect(inactive_membership_role.beitragskategorie).to eq("family")
        expect(inactive_membership_role).to be_a(Group::SektionsMitglieder::Mitglied)
        expect(mitglied.sac_family_main_person).to eq(false)
      end

      it "resets sac_family_main_person if previously set" do
        mitglied.update!(sac_family_main_person: true)
        row[:role] = "Mitglied (Stammsektion) (Einzel)"

        importer.create
        mitglied.reload
        expect(mitglied.sac_family_main_person).to eq(false)
      end
    end
  end
end
