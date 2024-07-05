# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Import::PeopleImporter do
  let(:file) { file_fixture("kontakte.xlsx") }
  let(:importer) { described_class.new(file, output: double(puts: nil)) }

  let(:people_navision_ids) { %w[100001 100002 100003 100004] }
  let(:invalid_person_navision_id) { "100005" }

  before do
    Person.where(id: people_navision_ids).destroy_all
  end

  it "imports people and assigns member role" do
    importer.import!

    people_navision_ids.each do |id|
      person = Person.find(id)
      expect(person).to be_present
      expect(person.roles.with_deleted.first).to be_a(Group::ExterneKontakte::Kontakt)
    end
  end

  it "imports natürliche person" do
    importer.import!

    person = Person.find(people_navision_ids.first)

    expect(person.first_name).to eq("Vorname 1")
    expect(person.last_name).to eq("Nachname 1")
    expect(person.address_care_of).to eq("Adresszusatz 1")
    expect(person.address).to eq("Adresse 1")
    expect(person.postbox).to eq("Postfach 1")
    expect(person.zip_code).to eq("3000")
    expect(person.town).to eq("Bern")
    expect(person.email).to eq("email1@example.com")
    expect(person.birthday).to eq(DateTime.new(2000, 10, 1))
    expect(person.gender).to eq("m")
    expect(person.language).to eq("de")

    expect(person.roles).to have(1).item
    expect(person.roles.first).to be_a(Group::ExterneKontakte::Kontakt)

    expect(person.phone_numbers.count).to eq(3)

    mobile = person.phone_numbers.find_by(label: "Mobil")
    expect(mobile.number).to eq("+41 79 000 00 01")

    main = person.phone_numbers.find_by(label: "Privat")
    expect(main.number).to eq("+41 32 000 00 01")

    main = person.phone_numbers.find_by(label: "Direkt")
    expect(main.number).to eq("+41 78 000 00 01")

    expect(person).to be_confirmed

    expect(person.company).to eq false
    expect(person.company_name).to be_nil
  end

  it "does not import invalid person" do
    importer.import!

    expect(Person.find_by(id: invalid_person_navision_id)).to be_nil
  end
end
