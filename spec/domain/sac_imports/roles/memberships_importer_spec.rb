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
    let!(:person2_other_role) { Fabricate(Group::AboMagazin::Abonnent.name.to_sym, person: person2, group: groups(:abo_die_alpen)) }
    let!(:person2_navision_import_role) { Fabricate(Group::ExterneKontakte::Kontakt.name.to_sym, person: person2, group: navision_import_group) }
    let!(:sac_winterthur_mitglieder) do
      section = Group::Sektion
        .create!(name: "SAC Winterthur",
                 foundation_year: 1900,
                 parent_id: Group.root.id)
      Group::SektionsMitglieder.find_by(parent_id: section.id)
    end

    it "reports people not found if they do not exist by navision id" do
      expected_output = []
      2.times { expected_output << "4200000 (Nachname 1 Vorname 1): ❌ Person not found in hitobito\n" }
      expected_output << "4200003 (Cochet Frederique): ❌ Person not found in hitobito\n"
      3.times { expected_output << "4200004 (Alder John): ❌ Person not found in hitobito\n" }
      expected_output << "4200005 (Muster Hans): ❌ Person not found in hitobito\n"
      expected_output << "4200006 (Buri Max): ❌ Person not found in hitobito\n"
      expected_output << "4200008 (Bühler Christian): ❌ Person not found in hitobito\n"

      expected_output.each do |output_line|
        expect(output).to receive(:print).with(output_line)
      end

      importer.create

      expect(csv_report.size).to eq(13)
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
                                      nil, nil, "Person not found in hitobito"])
    end

    it "creates/resets membership roles" do
      sac_chaux_fonds = Group::Sektion.create!(name: "CAS La Chaux-de-Fonds", foundation_year: 1942, parent_id: Group.root.id)
      person5 = Fabricate(:person, id: 4200005, first_name: "Hans", last_name: "Muster")

      expected_output = []
      expected_output << "4200005 (Muster Hans): ❌ No Section/Ortsgruppe group found for 'CAS Jaman'\n"
      #expected_output << "4200001 (Maurer Johannes): ❌ A previous role could not be imported for this person, skipping\n"
      expected_output << "4200002 (Potter Harry): ✅ Membership role created\n"

      expected_output.each do |output_line|
        expect(output).to receive(:print).with(output_line)
      end

      importer.create

      # person1
      ## creates new membership roles
      expect(person1.reload.roles.count).to eq(1) # should have only one active role
      person1_new_membership_role = person1.roles.find_by(type: Group::SektionsMitglieder::Mitglied.sti_name)
      expect(person1_new_membership_role).to be_a(Group::SektionsMitglieder::Mitglied)
      expect(person1_new_membership_role.group.parent).to eq(sac_chaux_fonds)
      expect(person1_new_membership_role.beitragskategorie).to eq("family")
      expect(person1_new_membership_role.created_at.to_date).to eq(Date.new(2018, 6, 7))
      expect(person1_new_membership_role.delete_on).to eq(Date.new(2024, 12, 31))
      expect(person1.sac_family_main_person).to eq(false)
      person1_new_inactive_membership_role = person1.roles.deleted.find_by(type: Group::SektionsMitglieder::Mitglied.sti_name)
      expect(person1_new_inactive_membership_role).to be_a(Group::SektionsMitglieder::Mitglied)
      expect(person1_new_inactive_membership_role.group.parent).to eq(sac_chaux_fonds)
      expect(person1_new_inactive_membership_role.beitragskategorie).to eq("adult")
      expect(person1_new_inactive_membership_role.created_at.to_date).to eq(Date.new(2014, 10, 6))
      expect(person1_new_inactive_membership_role.delete_on).to be_nil
      expect(person1_new_inactive_membership_role.deleted_at.to_date).to eq(Date.new(2018, 6, 6))

      ## but does not touch membership roles for people outside current NAV2
      expect(roles(:mitglied)).to be_persisted
      ## and does not touch non membership roles
      expect(person2_other_role.reload).to be_persisted

      # person2
      ## resets all existing membership roles
      person2_existing_membership_role_ids = [person2_membership_role.id,
                                              person2_additional_membership_role.id,
                                              person2_inactive_membership_role.id]
      expect(Role.with_deleted.where(id: person2_existing_membership_role_ids)).not_to exist
      ## creates new membership roles
      person2_new_membership_role = person2.roles.with_deleted.find_by(type: Group::SektionsMitglieder::Mitglied.sti_name)
      expect(person2_new_membership_role).to be_a(Group::SektionsMitglieder::Mitglied)
      expect(person2_new_membership_role.group).to eq(sac_winterthur_mitglieder)
      expect(person2_new_membership_role.beitragskategorie).to eq("adult")
      ## removes navision import role if present
      expect(person2.roles.where(group: navision_import_group)).not_to exist

      # person3
      ## does not remove navision import role if no membership role could be created
      #expect(person3.roles.where(group: navision_import_group)).to exist

      expect(csv_report.size).to eq(13)
      expect(csv_report.first).to eq(report_headers)
      expect(csv_report[5]).to eq(["4200002",
                                   "Potter Harry",
                                   "2014-10-06",
                                   "2020-01-29",
                                   "Sektion > SAC Winterthur > Mitglieder",
                                   "Mitglied (Stammsektion) (Einzel)",
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
