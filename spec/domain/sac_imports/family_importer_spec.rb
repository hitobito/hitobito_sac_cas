# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::FamilyImporter do
  let(:output) { double(puts: nil, print: nil) }
  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }
  let(:importer) { described_class.new(output: output) }

  let(:report_file) { Rails.root.join("log", "sac_imports", "nav1-2_sac_families_2024-01-23-11:42.csv") }
  let(:report_headers) { %w[navision_id hitobito_person household_key errors] }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  before do
    travel_to DateTime.new(2024, 1, 23, 10, 42)
    stub_const("SacImports::CsvSource::SOURCE_DIR", sac_imports_src)
  end

  context "with fixture data" do
    let(:household_key_in_fixture) { "F50235" }

    context "when person exists" do
      let(:person) { Fabricate(:person, id: 4200004, sac_family_main_person: true) }

      before do
        Fabricate(Group::SektionsMitglieder::Mitglied.name,
          group: groups(:bluemlisalp_mitglieder),
          person: person,
          beitragskategorie: "family")
      end

      it "changes the household key" do
        expect { importer.create }
          .to change { Person.find(4200004).household_key }.from(nil).to(household_key_in_fixture)

        expect(File.exist?(report_file)).to be_truthy
        expect(csv_report.size).to eq(4)
        expect(csv_report.first).to eq(report_headers)
        expect(csv_report.pluck(3).compact).to eq(["errors"] + ["No household_key found in NAV1 data"] * 3)
      end
    end
  end

  context "with mocked person_id_to_household_key" do
    let(:main_person) { Fabricate(:person, sac_family_main_person: true) }
    let(:second_person) { Fabricate(:person) }

    let(:person_household_mapping) do
      {
        main_person.id => "F50235",
        second_person.id => "F50235",
        people(:familienmitglied).id => "F42"
      }
    end

    def create_family_role!(person)
      role = Group::SektionsMitglieder::Mitglied.new(
        group: groups(:bluemlisalp_mitglieder),
        person_id: person.id,
        beitragskategorie: "family",
        created_at: Time.current,
        delete_on: Time.current.end_of_year
      )
      role.save!(context: :import)
    end

    before do
      create_family_role!(main_person)
      create_family_role!(second_person)
      person_household_mapping.each do |person_id, household_key|
        expect(importer).to receive(:person_id_to_household_key).with(person_id).and_return(household_key)
      end
      allow(importer).to receive(:person_id_to_household_key).and_return(nil)
    end

    it "creates the households accordingly" do
      expect { importer.create }
        .to change { main_person.reload.household_key }.from(nil).to("F50235")
        .and change { second_person.reload.household_key }.from(nil).to("F50235")

      expect(File.exist?(report_file)).to be_truthy
      expect(csv_report.size).to eq(4)
      expect(csv_report.first).to eq(report_headers)
      expect(csv_report.pluck(3).compact).to eq(["errors"] + ["Person has different household_key than the one in NAV1 data"] + ["No household_key found in NAV1 data"] * 2)
    end
  end
end
