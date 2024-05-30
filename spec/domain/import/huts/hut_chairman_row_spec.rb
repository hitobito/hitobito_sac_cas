# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Import::Huts::HutChairmanRow do
  let(:importer) { described_class.new(row) }

  let(:row) do
    Import::HutsImporter::HEADERS.keys.index_with { |_symbol| nil }.merge(
      contact_navision_id: '00003750',
      contact_name: 'Bluemlisalphuette',
      verteilercode: '4007.0',
      related_navision_id: '123456',
      related_last_name: 'Muster',
      related_first_name: 'Max',
      created_at: '06/10/2022',
    )
  end

  let!(:person) { Fabricate(:person, id: 123456) }
  let!(:sektion) { Fabricate(Group::Sektion.sti_name.to_sym, navision_id: 3750, foundation_year: 1980) }
  let!(:funktionaere) { sektion.children.find { |child| child.type == 'Group::SektionsFunktionaere' } }
  let!(:hut_comission) { Fabricate(Group::SektionsHuettenkommission.sti_name.to_sym, parent: funktionaere) }
  let!(:hut) { Fabricate(Group::SektionsHuette.sti_name.to_sym, parent: hut_comission) }
  let(:contact_role_group) { Group::ExterneKontakte.create!(name: 'Navision Import', parent_id: Group.root.id) }

  it 'imports role' do
    expect { importer.import! }.
      to change { Role.count }.by(1)

    role = Group::SektionsHuettenkommission::Huettenobmann.find_by(group: hut_comission, person: person)

    expect(role).to be_present
  end

  it 'does not import twice' do
    expect { importer.import! }.
      to change { Role.count }.by(1)

    role = Group::SektionsHuettenkommission::Huettenobmann.find_by(group: hut_comission, person: person)

    expect(role).to be_present

    expect { importer.import! }.
      to_not change { Role.count }
  end

  it 'removes placeholder contact role' do
    placeholder_contact_role = Group::ExterneKontakte::Kontakt.create!(group: contact_role_group, person: person)

    importer.import!

    expect(person.roles.size).to eq(1)
    expect(Role.exists?(placeholder_contact_role.id)).to eq(false)

    role = Group::SektionsHuettenkommission::Huettenobmann.find_by(group: hut_comission, person: person)

    expect(role).to be_present
  end
end
