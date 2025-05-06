# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

shared_examples "validates Neuanmeldung timestamps" do
  it "start_on is required" do
    role = described_class.new(person: people(:mitglied), start_on: nil)
    role.validate
    expect(role.errors[:start_on]).to include("muss ausgefüllt werden")

    role.start_on = Date.current
    role.validate
    expect(role.errors[:start_on]).to be_empty
  end

  it "delete_on is not required" do
    role = described_class.new(person: people(:mitglied), end_on: nil)
    role.validate
    expect(role.errors[:end_on]).to be_empty
  end
end

shared_examples "after destroy hook" do
  it "removes all neuanmeldung roles of family members" do
    household = Household.new(person, maintain_sac_family: false, validate_members: false)
    household.add(people(:mitglied))
    household.set_family_main_person!
    role = Fabricate(described_class.sti_name.to_sym, group: group, beitragskategorie: :family, person: person)

    depending_roles = []
    depending_roles += [
      [Group::SektionsNeuanmeldungenNv::Neuanmeldung, :bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv],
      [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion]
    ].map do |role_class, group|
      p = Fabricate(:person, birthday: 12.years.ago)
      household.add(p)
      household.save!
      r = Fabricate(role_class.sti_name.to_sym, group: groups(group), beitragskategorie: :family, person: p)
      r
    end

    depending_roles += [
      [Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion, :bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv],
      [Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion, :bluemlisalp_neuanmeldungen_sektion]
    ].map do |role_class, group|
      p = Fabricate(:person, birthday: 12.years.ago)
      household.add(p)
      household.save!
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym, group: groups(:matterhorn_mitglieder), person: p)
      r = Fabricate(role_class.sti_name.to_sym, group: groups(group), beitragskategorie: :family, person: p)
      r
    end

    expect do
      role.destroy!
    end.to change { Role.count }.by(-5)

    depending_roles.each do |depending_role|
      expect(Role.where(id: depending_role.id)).to eq([])
    end
  end
end
