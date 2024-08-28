# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

shared_examples "Mitglied dependant destroy" do
  let(:person) { Fabricate(:person) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:other_group) { groups(:matterhorn_mitglieder) }
  let(:role) { described_class.new(person: person, group: group) }

  it "gets soft deleted when Mitglied role gets soft deleted" do
    freeze_time
    mitglied_role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: group, person: person, created_at: 1.year.ago)

    role.save!
    expect(role).to be_valid

    mitglied_role.destroy

    role.reload
    expect(role).to be_paranoia_destroyed
    expect(role.deleted_at).to eq(mitglied_role.deleted_at)
    expect(role.person.primary_group_id).to be_nil
  end

  it "gets hard deleted when Mitglied role gets hard deleted" do
    mitglied_role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: group, person: person)

    role.save!
    expect(role).to be_valid

    mitglied_role.destroy

    expect(Role.with_inactive.exists?(id: role.id)).to eq(false)
    expect(role.person.primary_group_id).to be_nil
  end

  it "gets ended when MitgliedZusatzsektion role gets ended" do
    freeze_time
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other_group, person: person, start_on: 1.year.ago)
    mitglied_role = Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name, group: group, person: person, start_on: 1.year.ago)

    role.save!
    expect(role).to be_valid

    expect { mitglied_role.destroy }.to change { Role.with_inactive.find(mitglied_role.id).end_on }.from(nil)

    role.reload
    expect(role.end_on).to eq(mitglied_role.end_on)
    expect(role.person.primary_group).to eq(other_group)
  end

  it "gets hard deleted when MitgliedZusatzsektion role gets hard deleted" do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other_group, person: person)
    mitglied_role = Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name, group: group, person: person)

    role.save!
    expect(role).to be_valid

    mitglied_role.destroy

    expect(Role.with_inactive.exists?(id: role.id)).to eq(false)
    expect(role.person.primary_group).to eq(other_group)
  end
end
