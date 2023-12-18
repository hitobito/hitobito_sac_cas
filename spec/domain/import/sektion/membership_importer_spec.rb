# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Import::Sektion::MembershipsImporter do
  let(:group) { groups(:bluemlisalp) }

  def attrs(create_person: true, **attrs)
    @navision_id ||= 123
    person_id = attrs.delete(:navision_id).presence || @navision_id += 1
    Fabricate(:person, id: person_id) unless Person.where(id: person_id).exists?
    {
      group_navision_id: group.navision_id,
      beitragskategorie: 'EINZEL',
      navision_id: person_id,
      last_joining_date: '1.1.1960'
    }.merge(attrs)
  end


  let(:path) { instance_double(Pathname, exist?: true) }
  let(:output) { double(:output, puts: true) }
  subject(:importer) { described_class.new(path, output: output) }

  it 'noops if file does not exist' do
    expect(path).to receive(:exist?).and_return(false)
    expect(path).to receive(:to_path).and_return(:does_not_exist)
    expect(output).to receive(:puts).with("\nFAILED: Cannot read does_not_exist")
    importer.import!
  end

  it 'creates correct role in group' do
    id = 123
    expect(importer).to receive(:each_row).and_yield(attrs(navision_id: id))
    expect { importer.import! }.to change { Role.count }.by(1)

    person = Person.find(id)
    expect(person.roles).to have(1).item
    role = person.roles.first
    expect(role.beitragskategorie).to eq 'einzel'
    expect(role.group).to eq groups(:bluemlisalp_mitglieder)
    expect(role.created_at).to eq Time.zone.parse('1.1.1960')
  end

  it 'creates roles for multiple people' do
    expect(importer).to receive(:each_row)
      .and_yield(attrs)
      .and_yield(attrs)
    expect do
      importer.import!
    end.to change { Role.count }.by(2)
  end

  it 'updates existing if navision_id is identical' do
    id = 123
    expect(importer).to receive(:each_row)
      .and_yield(attrs(navision_id: id, last_joining_date: '1.1.1960'))
      .and_yield(attrs(navision_id: id, last_joining_date: '1.1.1970'))
    expect do
      importer.import!
    end.to change { Role.count }.by(1)

    person = Person.find(id)
    expect(person.roles).to have(1).items
    role = person.roles.first
    expect(role.created_at).to eq Time.zone.parse('1.1.1970')
  end

  describe 'families' do
    let!(:family_adult) { Fabricate(:person, birthday: 25.years.ago.to_date) }
    let!(:family_child) { Fabricate(:person, birthday: 10.years.ago.to_date) }

    before do
      expect(importer).to receive(:each_row)
        .and_yield(attrs(
                     navision_id: family_adult.id,
                     household_key: 'this-family',
                     beitragskategorie: 'FAMILIE'
                   ))
        .and_yield(attrs(
                     navision_id: family_child.id,
                     household_key: 'this-family',
                     beitragskategorie: 'FAMILIE'
                   ))
    end

    it 'imports household_key' do
      expect { importer.import! }.to change { Role.count }.by(2)
      expect(family_adult.reload.household_key).to eq 'this-family'
      expect(family_child.reload.household_key).to eq 'this-family'
    end

    it 'creates people_managers' do
      expect { importer.import! }.to change { PeopleManager.count }.by(1)
      pm = PeopleManager.last
      expect(pm.manager).to eq family_adult
      expect(pm.managed).to eq family_child
    end
  end

  describe 'multiple runs' do
    it 'does not duplicate roles' do
      expect(importer).to receive(:each_row)
        .and_yield(attrs(navision_id: 123)).twice
      expect do
        2.times { importer.import! }
      end.to change { Role.count }.by(1)
                                  .and change { Role.with_deleted.count }.by(1)

    end
  end
end
