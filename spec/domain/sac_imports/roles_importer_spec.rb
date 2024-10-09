# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::RolesImporter do
  let(:output) { double(puts: nil, print: nil) }
  let(:importer) { described_class.new(output: output, role_type: role_type) }

  # csv report
  let(:report_file) { Rails.root.join("log", "sac_imports", "nav2-1_roles_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[navision_id person_name valid_from valid_until target_group target_role message warning error] }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }

  around do |example|
    # make sure there's no csv report from previous run
    File.delete(report_file) if File.exist?(report_file)
    travel_to(DateTime.new(2024, 1, 23, 10, 42))

    example.run

    File.delete(report_file) if File.exist?(report_file)
    expect(File.exist?(report_file)).to be_falsey
    travel_back
  end

  context "with membership role type" do
    let(:role_type) { :membership }

    context "with NAV2 csv file fixture" do
      let!(:navision_import_group) { Group::ExterneKontakte.create!(name: "Navision Import", parent: Group.root) }

      let!(:person1) { Fabricate(:person, id: 4200001, first_name: "Johannes", last_name: "Maurer") }
      let!(:person1_navision_import_role) { Fabricate(Group::ExterneKontakte::Kontakt.name.to_sym, person: person1, group: navision_import_group) }
      let!(:sac_chaux_de_fonds) { Group::Sektion.create!(name: "CAS La Chaux-de-Fonds", parent: Group.root, foundation_year: 1942) }

      it "imports role from nav2 csv fixture file" do
        stub_const("SacImports::CsvSource::SOURCE_DIR", sac_imports_src)
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

        expect(csv_report.size).to eq(14)
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
        expect(csv_report[13]).to eq(["4200005",
                                     "Muster Hans",
                                     "2014-10-06",
                                     "2016-10-11",
                                     "Sektion > CAS Moléson > Mitglieder",
                                     "Mitglied (Zusatzsektion) (Einzel)",
                                     nil, nil, "A previous role could not be imported for this person, skipping"])
      end
    end
  end

end
