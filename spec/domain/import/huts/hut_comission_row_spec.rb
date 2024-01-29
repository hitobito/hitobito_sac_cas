# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Import::Huts::HutComissionRow do
let(:importer) { described_class.new(row) }

  let(:row) do
    Import::HutsImporter::HEADERS.keys.index_with { |_symbol| nil }.merge(
      contact_navision_id: '00003750',
      contact_name: 'Bluemlisalphuette',
      verteilercode: '3001',
      related_navision_id: '123456',
      related_last_name: 'Max',
      related_first_name: 'Muster',
      created_at: '06/10/2022',
    )
  end

  let!(:sektion) { Fabricate(Group::Sektion.sti_name.to_sym, navision_id: 3750, foundation_year: 1980) }

  it 'imports group' do
    expect { importer.import! }.
      to change { Group.count }.by(1)

    group = Group::SektionsHuettenkommission.find_by(parent: sektion)

    expect(group).to be_present
    expect(group.name).to eq(group.class.label)
  end

  it 'does not import twice' do
    expect { importer.import! }.
      to change { Group.count }.by(1)

    group = Group::SektionsHuettenkommission.find_by(parent: sektion)

    expect(group).to be_present
    expect(group.name).to eq(group.class.label)

    expect { importer.import! }.
      to_not change { Group.count }
  end
end
