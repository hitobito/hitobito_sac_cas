# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::PeopleImporter do
  let(:file) { file_fixture("sac_imports_src/NAV1_Kontakte_20240822_testdata.csv") }
  let(:importer) { described_class.new }

  let(:people_navision_ids) { %w[125099 125100 125101 125102 125103 125104 125105 125106 125107 125108] }
  let(:invalid_person_navision_id) { "125109" }

  before do
    Person.where(id: people_navision_ids).destroy_all

    # Mock the file loading behavior in CSVImporter
    csv_source_instance = SacImports::CsvSource.new(:NAV1)
    allow(csv_source_instance).to receive(:path).and_return(file)
    importer.instance_variable_set(:@source_file, csv_source_instance)
  end

  it "imports people and assigns member role" do
    importer.create

    people_navision_ids.each do |id|
      person = Person.find(id)
      expect(person).to be_present
      expect(person.roles.with_deleted.first).to be_a(Group::ExterneKontakte::Kontakt)
    end
  end

  it "imports natürliche person" do
    importer.create

    person = Person.find(people_navision_ids.first)

    expect(person.first_name).to eq("Vorname 1")
    expect(person.last_name).to eq("Nachname 1")
    expect(person.address_care_of).to eq("Adresszusatz 1")
    expect(person.postbox).to eq("Postfach 1")
    expect(person.zip_code).to eq("3766")
    expect(person.town).to eq("Boltigen")
    expect(person.birthday).to eq(DateTime.new(1988, 1, 1))
    expect(person.gender).to eq("m")
    expect(person.language).to eq("de")

    expect(person.roles).to have(1).item
    expect(person.roles.first).to be_a(Group::ExterneKontakte::Kontakt)

    expect(person.phone_numbers.count).to eq(1)

    main = person.phone_numbers.find_by(label: "Hauptnummer")
    expect(main.number).to eq("+41 78 764 12 62")

    expect(person).to be_confirmed

    expect(person.company).to eq false
    expect(person.company_name).to be_nil
  end

  it "does not import invalid person" do
    importer.create

    expect(Person.find_by(id: invalid_person_navision_id)).to be_nil
  end
end
