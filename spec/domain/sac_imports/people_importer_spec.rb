# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::PeopleImporter do
  let(:root) { Fabricate(:person, email: Settings.root_email) }
  let(:group) { groups(:bluemlisalp) }

  def attrs(**attrs)
    @navision_id ||= 123
    SacImports::PeopleImporter.headers.keys.map { |symbol| [symbol, nil] }.to_h.merge(
      navision_id: attrs[:navision_id] || @navision_id += 1,
      birthday: 40.years.ago.to_date,
      language: :DES,
      first_name: "first-name",
      last_name: "last-name"
    ).merge(attrs)
  end

  let(:path) { instance_double(Pathname, exist?: true) }
  let(:output) { double(:output, puts: true) }

  subject(:importer) { described_class.new(path, output: output) }

  it "noops if file does not exist" do
    expect(path).to receive(:exist?).and_return(false)
    expect(path).to receive(:to_path).and_return(:does_not_exist)
    expect(output).to receive(:puts).with("\nFAILED: Cannot read does_not_exist")
    importer.import!
  end

  it "creates person with correct role in group" do
    expect(importer).to receive(:each_row).and_yield(attrs(first_name: "test"))
    expect do
      importer.import!
    end.to change { Person.count }.by(1)
      .and change { Role.count }.by(1)

    person = Person.find_by(first_name: "test")
    expect(person.first_name).to eq "test"
    expect(person.language).to eq "de"
    expect(person.roles.first.group.type).to eq "Group::ExterneKontakte"
  end

  it "creates multiple people" do
    expect(importer).to receive(:each_row)
      .and_yield(attrs(first_name: "test"))
      .and_yield(attrs(first_name: "test2"))
    expect do
      importer.import!
    end.to change { Person.count }.by(2)
      .and change { Role.count }.by(2)
  end

  it "updates existing person with id=navision_id" do
    Fabricate(:person, id: 42, first_name: "old name")

    expect(importer).to receive(:each_row)
      .and_yield(attrs(first_name: "new name", navision_id: 42))

    expect { importer.import! }.to change { Person.find(42).first_name }.to("new name")
      .and not_change { Person.count }
  end

  it "logs error messages from people that could not be imported" do
    expect(importer).to receive(:each_row)
      .and_yield(attrs(birthday: "01.01.20000"))
    expect(output).to receive(:puts).with("Die folgenden 1 Personen waren ungültig:")
    expect(output).to receive(:puts)
      .with(" last-name first-name (124): Geburtstag muss vor 01.01.10000 sein")
    expect do
      importer.import!
    end.not_to change { Person.count }
    expect(importer.errors).to have(1).item
  end

  it "logs invalid emails but imports person without email" do
    expect(importer).to receive(:each_row)
      .and_yield(attrs(email: "adsf@zcnet.ch"))
    expect(Truemail).to receive(:valid?).at_least(:once).with("adsf@zcnet.ch").and_return(false)

    expect(output).to receive(:puts).with("Die folgenden 1 Emails waren ungültig:")
    expect(output).to receive(:puts).with(" last-name first-name (124): adsf@zcnet.ch")
    expect do
      importer.import!
    end.to change { Person.count }
    expect(importer.invalid_emails).to have(1).item
  end

  describe "duplicate emails" do
    it "treats person email as nil if Person with identical email exists" do
      Fabricate(:person, email: "test1@example.com")
      expect(importer).to receive(:each_row)
        .and_yield(attrs(first_name: "test1", email: "test1@example.com"))

      expect do
        importer.import!
      end.to change { Person.count }.by(1)
      expect(Person.find_by(first_name: "test1").email).to be_blank
    end

    it "treats person email as nil on second row if previous row with identical email exists" do
      expect(importer).to receive(:each_row)
        .and_yield(attrs(first_name: "test1", email: "test1@example.com"))
        .and_yield(attrs(first_name: "test2", email: "test1@example.com"))

      expect do
        importer.import!
        expect(importer.errors).to be_empty
      end.to change { Person.count }.by(2)
      expect(Person.find_by(first_name: "test2").email).to be_blank
    end

    it "ignores case for duplicate email detection" do
      expect(importer).to receive(:each_row)
        .and_yield(attrs(first_name: "test1", email: "test1@example.com"))
        .and_yield(attrs(first_name: "test2", email: "Test1@example.com"))

      expect do
        importer.import!
        expect(importer.errors).to be_empty
      end.to change { Person.count }.by(2)
      expect(Person.find_by(first_name: "test2").email).to be_blank
    end
  end

  describe "callbacks" do
    it "does not enqueue job nor sends email" do
      expect(importer).to receive(:each_row)
        .and_yield(attrs(first_name: "test", email: "test@example.com"))
      expect do
        importer.import!
      end.to change { Person.count }.by(1)
        .and not_change { Delayed::Job.count }
        .and(not_change { ActionMailer::Base.deliveries.size })
    end
  end

  describe "multiple runs" do
    it "does not duplicate person, roles or phone numbers" do
      expect(importer).to receive(:each_row)
        .and_yield(attrs(first_name: "test", email: "test@example.com", phone: "079 12 123 10"))
        .twice
      expect do
        2.times { importer.import! }
      end.to change { Person.count }.by(1)
        .and change { Role.with_deleted.count }.by(1)
        .and change { PhoneNumber.count }.by(1)
    end
  end
end
