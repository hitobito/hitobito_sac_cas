# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

xdescribe SacImports::Nav1PeopleImporter, versioning: true do
  let(:output) { double(puts: nil, print: nil) }
  let(:nav1_csv_fixture) { file_fixture("sac_imports_src/NAV1_fixture.csv") }
  let(:importer) { described_class.new(output: output) }

  let(:people_navision_ids) { %w[4200000 4200001 4200002 4200003 4200004 4200005 4200006 4200007 4200008 4200009] }
  let(:invalid_person_navision_id) { "4200010" }

  let(:report_file) { Rails.root.join("log", "sac_imports", "nav1-1_people_2024-01-23-1142.csv") }
  let(:report_headers) { %w[navision_membership_number navision_name status warnings errors] }
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

  def run_import(**kw_args)
    allow(Truemail.configuration).to receive(:default_validation_type).and_return(:regex)
    Tempfile.create do |file|
      file.write(nav1_csv_fixture.read.lines[1..].join)
      file.rewind

      # Mock the file loading behavior in CSVImporter
      csv_source_instance = SacImports::CsvSource.new(:NAV1)
      allow(csv_source_instance).to receive(:path).and_return(file)
      importer.instance_variable_set(:@source_file, csv_source_instance)
      importer.create(**kw_args)
      File.unlink file
    end
  end

  it "creates csv report entries for people with errors" do
    expected_output = Array.new(10) { /\d+ \(.*\): ✅\n/ }
    expected_output << "#{invalid_person_navision_id} ( ): ❌ Bitte geben Sie einen Namen ein\n"

    expected_output.each do |output_line|
      expect(output).to receive(:print).with(output_line)
    end
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    run_import

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(2)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report.second).to eq([invalid_person_navision_id, " ", "error", nil, "Bitte geben Sie einen Namen ein"])
  end

  it "does not create version entries for imported people" do
    expect { run_import }
      .not_to change { PaperTrail::Version.count }
  end

  it "imports people and assigns role" do
    run_import

    people_navision_ids.each do |id|
      person = Person.find(id)
      expect(person).to be_present
      expect(person.roles.count).to eq(1)
      expect(person.roles.first).to be_a(Group::ExterneKontakte::Kontakt)
    end
  end

  it "imports natürliche person" do
    run_import

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
    expect(main.number).to eq("+41 77 999 99 99")

    expect(person).to be_confirmed

    expect(person.company).to eq false
    expect(person.company_name).to be_nil
  end

  it "does not import invalid person" do
    run_import

    expect(Person.find_by(id: invalid_person_navision_id)).to be_nil
  end

  context "for person having already taken email" do
    let(:email) { "example@example.com" }

    before { Fabricate(:person, email: email) }

    it "adds email as additional email" do
      run_import

      person = Person.find(people_navision_ids.first)
      expect(person.email).to be_blank
      expect(person.additional_emails.count).to eq(1)
      expect(person.additional_emails.first.email).to eq(email)
      expect(person.additional_emails.first.label).to eq("Duplikat")
    end

    it "does not add email as additional email if it already exists" do
      person = Person.new(id: "4200000").tap { |p| p.save(validate: false) }
      person.additional_emails.create!(email: email, label: "Duplikat")

      expect { run_import }
        .not_to change { person.additional_emails.count }
    end
  end

  context "with start_at_navision_id" do
    it "starts imported from given navision_id" do
      expected_output = ["Starting import from row with navision_id 4200008 (Bühler Christian)\n"]
      expected_output << "4200008 (Christian Bühler): ✅\n"
      expected_output << "4200009 (Scarlett Gygax): ✅\n"
      expected_output << "#{invalid_person_navision_id} ( ): ❌ Bitte geben Sie einen Namen ein\n"

      expected_output.each do |output_line|
        expect(output).to receive(:print).with(output_line)
      end
      expect(output).to receive(:puts).with("Report written to #{report_file}")

      run_import(start_at_navision_id: "4200008")
    end
  end
end
