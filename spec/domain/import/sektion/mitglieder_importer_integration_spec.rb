# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'
require_relative '../../../../../lib/hitobito_sac_cas/import/sektion/mitglieder_importer'

describe Import::Sektion::MitgliederImporter do

  let!(:root) { Fabricate(:person, email: Settings.root_email) }

  let(:file) { file_fixture('bluemlisalp_people.xlsx') }
  let(:importer) { described_class.new(file, root, output: double(puts: nil)) }

  let(:people_navision_ids) { %w(213134 102345 459233 348212 131348) }
  let(:invalid_person_navision_id) { '312311' }

  before do
    Person.where(id: people_navision_ids).destroy_all
  end

  it 'imports people and assigns member role' do
    importer.import!

    people_navision_ids.each do |id|
      person = Person.find(id)
      expect(person).to be_present
      expect(person.roles.with_deleted.first).to be_a(Group::SektionsMitglieder::Mitglied)
    end
  end

  it 'imports active person' do
    importer.import!

    active = Person.find(people_navision_ids.second)

    expect(active.household_key).to be_nil
    expect(active.first_name).to eq('Pascal')
    expect(active.last_name).to eq('Simon')
    expect(active.address).to eq('Landweg 8A')
    expect(active.zip_code).to eq('3604')
    expect(active.town).to eq('Thun')
    expect(active.email).to eq('simon@puzzle.ch')
    expect(active.birthday).to eq(DateTime.new(1941, 5, 28))
    expect(active.gender).to eq('m')
    expect(active.language).to eq('fr')

    active_role = active.roles.first

    expect(active_role.created_at).to eq(DateTime.new(1899, 12, 31))
    expect(active_role.deleted_at).to be_nil
    expect(active_role.beitragskategorie).to eq('jugend')

    expect(active.phone_numbers.count).to eq(3)

    mobile = active.phone_numbers.find_by(label: 'Mobil')
    expect(mobile.number).to eq('+41 79 300 30 30')

    main = active.phone_numbers.find_by(label: 'Privat')
    expect(main.number).to eq('+41 34 300 30 30')

    main = active.phone_numbers.find_by(label: 'Direkt')
    expect(main.number).to eq('+41 34 123 45 67')

    expect(active).to be_confirmed
  end

  it 'imports retired person' do
    importer.import!

    retired = Person.find(people_navision_ids.first)

    expect(retired.household_key).to eq('F12345')
    expect(retired.first_name).to eq('Olivier')
    expect(retired.last_name).to eq('Brian')

    # the address should be one of the last imported person of the family/household
    expect(retired.address).to eq('Seestrasse 12')
    expect(retired.zip_code).to eq('8000')
    expect(retired.town).to eq('Zürich')

    expect(retired.email).to eq('brian@puzzle.ch')
    expect(retired.birthday).to eq(DateTime.new(1960, 1, 1))
    expect(retired.gender).to eq('m')
    expect(retired.language).to eq('de')

    expect(retired.roles.without_deleted).to eq []
    retired_role = retired.roles.with_deleted.first

    expect(retired_role.created_at).to eq(DateTime.new(1980, 12, 31))
    expect(retired_role.deleted_at).to eq(DateTime.new(2010, 1, 1))
    expect(retired_role.beitragskategorie).to eq('einzel')
  end

  it 'sets the address of all family/household members to the one of the last imported member' do
    importer.import!

    family = Person.where(household_key: 'F12345')
    expect(family.count).to eq 3

    expect(family).to all have_attributes(
      address: 'Seestrasse 12',
      zip_code: '8000',
      town: 'Zürich'
    )
  end

  it 'does not import invalid person' do
    importer.import!

    expect(Person.find_by(id: invalid_person_navision_id)).to be_nil
  end

  it 'imports beitragskategorie' do
    importer.import!

    beitragskategorien =
      Group::SektionsMitglieder::Mitglied
      .where(person_id: people_navision_ids)
      .pluck(:beitragskategorie)

    expect(beitragskategorien).to eq(['jugend', 'familie', 'familie', 'familie'])
  end
end
