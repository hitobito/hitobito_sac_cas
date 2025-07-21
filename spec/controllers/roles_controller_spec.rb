#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe RolesController do
  before { sign_in(people(:admin)) }

  let(:person) { Fabricate(:person) }

  describe "DELETE destroy" do
    let!(:household) do
      household = Household.new(person, maintain_sac_family: false, validate_members: false)
      household.set_family_main_person!
      household
    end

    def build_depending_roles_and_family(beitragskategorie: :family)
      [
        [Group::SektionsNeuanmeldungenNv::Neuanmeldung, :bluemlisalp_neuanmeldungen_nv, false],
        [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion, false],
        [Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion, :bluemlisalp_neuanmeldungen_nv, true],
        [Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion, :bluemlisalp_neuanmeldungen_sektion, true]
      ].map do |role_class, group, add_membership_role|
        build_depending_role_and_add_to_family(role_class, group, add_membership_role:, beitragskategorie:)
      end
    end

    def build_depending_role_and_add_to_family(role_class, group, add_membership_role: false, beitragskategorie: :family)
      p = Fabricate(:person, birthday: 12.years.ago)
      household.add(p)
      household.save!
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym, group: groups(:matterhorn_mitglieder), person: p) if add_membership_role
      Fabricate(role_class.sti_name.to_sym, group: groups(group), beitragskategorie:, person: p)
    end

    context "for family neuanmeldungs role" do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }

      it "destroys household" do
        role = Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: group, beitragskategorie: :family, person: person)

        other = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym, group: groups(:matterhorn_mitglieder)).person
        other2 = Fabricate(:person, birthday: 12.years.ago)

        household.add(other)
        household.add(other2)
        household.save!

        expect(household.people).to match_array([person, other, other2])

        delete :destroy, params: {group_id: group.id, id: role.id}

        household = person.reload.household

        expect(household.people).to match_array([person])
      end

      it "destroys family neuanmeldung roles in same layer" do
        household.add(people(:mitglied))
        role = Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: group, beitragskategorie: :family, person: person)

        depending_roles = build_depending_roles_and_family

        delete :destroy, params: {group_id: group.id, id: role.id}

        depending_roles.each do |depending_role|
          expect(Role.where(id: depending_role.id)).to_not be_present
        end
      end

      it "replaces family neuanmeldung roles in other layer with new beitragskategorie" do
        household.add(people(:mitglied))
        role = Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: group, beitragskategorie: :family, person: person)

        depending_role = build_depending_role_and_add_to_family(Group::SektionsNeuanmeldungenNv::Neuanmeldung, :matterhorn_neuanmeldungen_nv)

        delete :destroy, params: {group_id: group.id, id: role.id}

        expect(Role.where(id: depending_role.id)).not_to be_present
        new_role = Role.find_by(person_id: depending_role.person_id)
        expect(new_role).to be_present
        expect(new_role.beitragskategorie).to eq "youth"
        expect(new_role.group).to eq depending_role.group
      end
    end

    context "for adult neuanmeldungs role" do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }

      it "does not destroy depending adult neuanmeldung roles" do
        household.add(people(:mitglied))
        role = Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: group, beitragskategorie: :adult, person: person)

        depending_roles = build_depending_roles_and_family(beitragskategorie: :adult)

        delete :destroy, params: {group_id: group.id, id: role.id}

        depending_roles.each do |depending_role|
          expect(Role.find_by(person_id: depending_role.person_id, group_id: depending_role.group_id)).to be_present
        end
      end
    end

    context "for abo role" do
      let(:group) { groups(:abo_die_alpen) }

      it "does not destroy household" do
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: groups(:bluemlisalp_neuanmeldungen_nv), beitragskategorie: :family, person: person)
        role = Fabricate(Group::AboMagazin::Andere.sti_name.to_sym, group: group)

        other = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym, group: groups(:matterhorn_mitglieder)).person
        other2 = Fabricate(:person, birthday: 12.years.ago)

        household.add(other)
        household.add(other2)
        household.save!

        expect(household.people).to match_array([person, other, other2])

        delete :destroy, params: {group_id: group.id, id: role.id}

        household = person.reload.household

        expect(household.people).to match_array([person, other, other2])
      end

      it "does not destroy family neuanmeldung roles in same layer" do
        household.add(people(:mitglied))
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: groups(:bluemlisalp_neuanmeldungen_nv), beitragskategorie: :adult, person: person)
        role = Fabricate(Group::AboMagazin::Andere.sti_name.to_sym, group: group)

        depending_roles = build_depending_roles_and_family

        delete :destroy, params: {group_id: group.id, id: role.id}

        depending_roles.each do |depending_role|
          expect(Role.where(id: depending_role.id)).to be_present
        end
      end
    end
  end
end
