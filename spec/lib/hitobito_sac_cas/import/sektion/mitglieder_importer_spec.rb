# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Import::Sektion::MitgliederImporter do

  let(:group) { groups(:bluemlisalp) }

  let(:required_attrs) {
  }

  def attrs(attrs = {})
    @navision_id ||= 123
    {
      language: :DES, group_navision_id: group.navision_id, beitragskategorie: 'EINZEL',
      navision_id: (attrs.delete(:navision_id).presence ||  @navision_id += 1),
      birthday: 40.years.ago.to_date
    }.merge(attrs)
  end


  let(:path) { instance_double(Pathname, exist?: true) }
  let(:output) {  double(:output, puts: true) }
  subject(:importer) { described_class.new(path, output: output) }

  it 'noops if file does not exist' do
    expect(path).to receive(:exist?).and_return(false)
    expect(path).to receive(:to_path).and_return(:does_not_exist)
    expect(output).to receive(:puts).with("\nFAILED: Cannot read does_not_exist")
    importer.import!
  end

  it 'creates person with correct role in group' do
    expect(importer).to receive(:each_row).and_yield(attrs(first_name: 'test'))
    expect do
      importer.import!
    end.to change { Person.count }.by(1)
      .and change { Role.count }.by(1)

    person = Person.find_by(first_name: 'test')
    expect(person.first_name).to eq 'test'
    expect(person.language).to eq 'de'
    expect(person.roles.first.beitragskategorie).to eq 'einzel'
    expect(person.roles.first.group).to eq groups(:bluemlisalp_mitglieder)
  end

  it 'creates multiple people' do
    expect(importer).to receive(:each_row)
      .and_yield(attrs(first_name: 'test'))
      .and_yield(attrs(first_name: 'test2'))
    expect do
      importer.import!
    end.to change { Person.count }.by(2)
      .and change { Role.count }.by(2)
  end

  it 'updates existing if navision_id is identical' do
    expect(importer).to receive(:each_row)
      .and_yield(attrs(first_name: 'test'))
      .and_yield(attrs(first_name: 'test2', navision_id: @navision_id))
    expect do
      importer.import!
    end.to change { Person.count }.by(1)
  end

  it 'logs error messages from people that could not be imported because of age' do
    expect(importer).to receive(:each_row)
      .and_yield(attrs(first_name: 'test', birthday: 3.days.ago))
    expect(output).to receive(:puts).with('Die folgenden 1 Personen waren ungültig:')
    expect(output).to receive(:puts).with(' test(124): Rollen ist nicht gültig, Person muss ein ' \
                                          'Geburtsdatum haben und mindestens 6 Jahre alt sein')
    expect do
      importer.import!
    end.not_to change { Person.count }
    expect(importer.errors).to have(1).item
  end

  it 'logs invalid emails but imports person without email' do
    expect(importer).to receive(:each_row)
      .and_yield(attrs(first_name: 'test', email: 'adsf@zcnet.ch'))
    expect(Truemail).to receive(:valid?).with('adsf@zcnet.ch').and_return(false)

    expect(output).to receive(:puts).with('Die folgenden 1 Emails waren ungültig:')
    expect(output).to receive(:puts).with(' test(124): adsf@zcnet.ch')
    expect do
      importer.import!
    end.to change { Person.count }
    expect(importer.invalid_emails).to have(1).item
  end

  describe 'duplicate emails' do
    it 'treats person email as nil if Person with identical email exists' do
      Fabricate(:person, email: 'test1@example.com')
      expect(importer).to receive(:each_row)
        .and_yield(attrs(first_name: 'test1', email: 'test1@example.com'))

      expect do
        importer.import!
      end.to change { Person.count }.by(1)
      expect(Person.find_by(first_name: 'test1').email).to be_blank
    end

    it 'treats person email as nil on second row if previous row with identical email exists' do
      expect(importer).to receive(:each_row)
        .and_yield(attrs(first_name: 'test1', email: 'test1@example.com'))
        .and_yield(attrs(first_name: 'test2', email: 'test1@example.com'))

      expect do
        importer.import!
        expect(importer.errors).to be_empty
      end.to change { Person.count }.by(2)
      expect(Person.find_by(first_name: 'test2').email).to be_blank
    end
  end

  describe 'callbacks' do
    it 'does not enqueue job nor sends email' do
    expect(importer).to receive(:each_row)
      .and_yield(attrs(first_name: 'test', email: 'test@example.com'))
    expect do
      importer.import!
    end.to change { Person.count }.by(1)
      .and not_change { Delayed::Job.count }
      .and not_change { ActionMailer::Base.deliveries.size }
    end
  end

  describe 'multiple runs' do
    it 'does not duplicate person, roles or phone numbers' do
      expect(importer).to receive(:each_row)
        .and_yield(attrs(first_name: 'test', email: 'test@example.com', phone: '079 12 123 10'))
        .twice
      expect do
        2.times { importer.import! }
      end.to change { Person.count }.by(1)
        .and change { Role.with_deleted.count }.by(1)
        .and change { PhoneNumber.count }.by(1)
    end
  end
end
