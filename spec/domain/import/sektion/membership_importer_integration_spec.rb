# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Import::Sektion::MembershipsImporter do

  let!(:root) { Fabricate(:person, email: Settings.root_email) }

  let(:file) { file_fixture('mitglieder_aktive.xlsx') }
  let(:importer) { described_class.new(file, output: double(puts: nil)) }

  let(:people_navision_ids) { %w(213134 102345 459233 348212 131348) }

  before do
    people_navision_ids.each do |id|
      Fabricate(
        :person,
        id: id,
        address: "Seestrasse #{id}",
        zip_code: id[0..3],
        town: 'Zürich'
      )
    end
  end

  it 'assigns member role' do
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

    active_role = active.roles.first

    expect(active_role.created_at).to eq(Time.zone.parse('1899-12-31'))
    expect(active_role.deleted_at).to be_nil
    expect(active_role.beitragskategorie).to eq('jugend')
  end

  it 'imports retired person' do
    importer.import!

    retired = Person.find(people_navision_ids.first)

    expect(retired.household_key).to eq('F12345')

    expect(retired.roles.without_deleted).to eq []
    retired_role = retired.roles.with_deleted.first

    expect(retired_role.created_at).to eq(Time.zone.parse('1980-12-31'))
    expect(retired_role.deleted_at).to eq(Time.zone.parse('2010-1-1'))
    expect(retired_role.beitragskategorie).to eq('einzel')
  end

  it 'sets the address of all family/household members to the one of the last imported member' do
    importer.import!

    family = Person.where(household_key: 'F12345')
    expect(family.count).to eq 3
    
    expect(family).to all have_attributes(
      address: "Seestrasse #{people_navision_ids.first}",
      zip_code: people_navision_ids.first[0..3],
      town: 'Zürich'
    )
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
