#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe RolesController do
  before { sign_in(people(:admin)) }

  let(:person) { Fabricate(:person) }

  describe "DELETE destroy" do
    context "for family neuanmeldungs role" do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }

      it "destroys household" do
        household = Household.new(person, maintain_sac_family: false, validate_members: false)
        household.set_family_main_person!
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

      it "destroys family neuanmeldung roles" do
        household = Household.new(person, maintain_sac_family: false, validate_members: false)
        household.add(people(:mitglied))
        household.set_family_main_person!
        role = Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: group, beitragskategorie: :family, person: person)

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

        delete :destroy, params: {group_id: group.id, id: role.id}

        depending_roles.each do |depending_role|
          expect(Role.where(id: depending_role.id)).to_not be_present
        end
      end
    end

    context "for adult neuanmeldungs role" do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }

      it "does not destroy family neuanmeldung roles" do
        household = Household.new(person, maintain_sac_family: false, validate_members: false)
        household.add(people(:mitglied))
        household.set_family_main_person!
        role = Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: group, beitragskategorie: :adult, person: person)

        depending_roles = []
        depending_roles += [
          [Group::SektionsNeuanmeldungenNv::Neuanmeldung, :bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv],
          [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion]
        ].map do |role_class, group|
          p = Fabricate(:person, birthday: 12.years.ago)
          household.add(p)
          household.save!
          r = Fabricate(role_class.sti_name.to_sym, group: groups(group), beitragskategorie: :adult, person: p)
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
          r = Fabricate(role_class.sti_name.to_sym, group: groups(group), beitragskategorie: :adult, person: p)
          r
        end

        delete :destroy, params: {group_id: group.id, id: role.id}

        depending_roles.each do |depending_role|
          expect(Role.where(id: depending_role.id)).to be_present
        end
      end
    end

    context "for abo role" do
      let(:group) { groups(:abo_die_alpen) }

      it "does not destroy household" do
        household = Household.new(person, maintain_sac_family: false, validate_members: false)
        household.set_family_main_person!
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

      it "does not destroy family neuanmeldung roles" do
        household = Household.new(person, maintain_sac_family: false, validate_members: false)
        household.add(people(:mitglied))
        household.set_family_main_person!
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: groups(:bluemlisalp_neuanmeldungen_nv), beitragskategorie: :adult, person: person)
        role = Fabricate(Group::AboMagazin::Andere.sti_name.to_sym, group: group)

        depending_roles = []
        depending_roles += [
          [Group::SektionsNeuanmeldungenNv::Neuanmeldung, :bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv],
          [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion]
        ].map do |role_class, group|
          p = Fabricate(:person, birthday: 12.years.ago)
          household.add(p)
          household.save!
          r = Fabricate(role_class.sti_name.to_sym, group: groups(group), beitragskategorie: :adult, person: p)
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
          r = Fabricate(role_class.sti_name.to_sym, group: groups(group), beitragskategorie: :adult, person: p)
          r
        end

        delete :destroy, params: {group_id: group.id, id: role.id}

        depending_roles.each do |depending_role|
          expect(Role.where(id: depending_role.id)).to be_present
        end
      end
    end
  end
end
