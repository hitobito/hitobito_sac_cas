# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

shared_examples 'Mitglied role required' do
  let(:person) { Fabricate(:person) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:other_group) { groups(:matterhorn_mitglieder) }
  let(:role) { described_class.new(person: person, group: group) }

  it 'is invalid without Mitglied role in group' do
    expect(role).to_not be_valid
    expect(role.errors[:person]).to include('muss Mitglied in der ausgewählten Gruppe sein.')
  end

  it 'is invalid with Mitglied role in different group' do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other_group, person: person)

    expect(role).to_not be_valid
    expect(role.errors[:person]).to include('muss Mitglied in der ausgewählten Gruppe sein.')
  end

  it 'is valid with Mitglied role in group' do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: group, person: person)
    expect(role).to be_valid
  end

  it 'is invalid without MitgliedZusatzsektion role in group' do
    expect(role).to_not be_valid
    expect(role.errors[:person]).to include('muss Mitglied in der ausgewählten Gruppe sein.')
  end

  it 'is invalid with MitgliedZusatzsektion role in different group' do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), person: person)
    Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name, group: other_group, person: person)

    expect(role).to_not be_valid
    expect(role.errors[:person]).to include('muss Mitglied in der ausgewählten Gruppe sein.')
  end

  it 'is valid with MitgliedZusatzsektion role in group' do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other_group, person: person)
    Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name, group: group, person: person)

    expect(role).to be_valid
  end
end
