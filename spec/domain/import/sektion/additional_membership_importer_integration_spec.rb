# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Import::Sektion::AdditionalMembershipsImporter do

  let(:file) { file_fixture('zusatzmitgliedschaften.xlsx') }
  let(:importer) { described_class.new(file, output: double(puts: nil)) }

  let(:person) do
    Fabricate(
      :person,
      id: 424242,
      address: "Seestrasse 42",
      zip_code: 8000,
      town: 'Zürich'
    )
  end

  before do
    Fabricate(Group::Sektion.sti_name.to_sym, navision_id: 3750, foundation_year: 1980)
  end

  it 'imports role' do
    expect { importer.import! }.
      to change { Role.count }.by(1).
      and change { person.roles.count }.by(1)

    role = person.roles.first
    expect(role).to be_a(Group::SektionsMitglieder::MitgliedZusatzsektion)
    expect(role.beitragskategorie).to eq('adult')
    expect(role.created_at).to eq(Time.zone.parse('01.01.1900'))
    expect(role.delete_on).to eq(Date.parse('2024-12-31'))
  end

  it 'ignores unknown person' do
    person.destroy
    expect { importer.import! }.not_to change { Role.count }
    expect(importer.errors).to eq ["Person 424242 existiert nicht"]
  end
end
