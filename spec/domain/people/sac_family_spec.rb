# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::SacFamily do
  let(:adult) { people(:familienmitglied) }
  let(:adult2) { people(:familienmitglied2) }
  let(:child) { people(:familienmitglied_kind) }

  let(:today) { Time.zone.today }
  let(:end_of_year) do
    if today == today.end_of_year
      (today + 1.days).end_of_year
    else
      today.end_of_year
    end
  end

  let!(:household_member_youth) do
    person = Fabricate(:person, household_key: "4242", birthday: today - 19.years)
    Group::SektionsMitglieder::Mitglied.create!(
      group: groups(:bluemlisalp_mitglieder),
      person: person,
      beitragskategorie: :youth,
      created_at: today.beginning_of_year,
      delete_on: end_of_year
    )
    person
  end

  let!(:household_member_adult) do
    person = Fabricate(:person, household_key: "4242", birthday: today - 42.years)
    Group::SektionsMitglieder::Mitglied.create!(
      group: groups(:bluemlisalp_mitglieder),
      person: person,
      beitragskategorie: :adult,
      created_at: today.beginning_of_year,
      delete_on: end_of_year
    )
    person
  end

  let!(:household_other_sektion_member) do
    person = Fabricate(:person, household_key: "4242", birthday: today - 88.years)
    Group::SektionsMitglieder::Mitglied.create!(
      group: groups(:matterhorn_mitglieder),
      person: person,
      beitragskategorie: :adult,
      created_at: today.beginning_of_year,
      delete_on: end_of_year
    )
    person
  end

  context "#family_members" do
    it "returns all family members" do
      expect(adult.sac_family.family_members).to contain_exactly(adult, adult2, child)
    end

    it "returns all family members when called on non-family housemate" do
      expect(household_member_adult.sac_family.family_members).to contain_exactly(adult, adult2, child)
    end

    it "returns all family members linked by neuanmeldung roles" do
      Group::SektionsMitglieder::Mitglied.where(group: groups(:bluemlisalp_mitglieder))
        .update_all(group_id: groups(:bluemlisalp_neuanmeldungen_sektion).id,
          created_at: 7.days.ago,
          delete_on: today + 20.days,
          type: Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name)

      expect(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.count).to eq(6)

      family_members = adult.sac_family.family_members

      expect(family_members).to include adult
      expect(family_members).to include adult2
      expect(family_members).to include child

      expect(family_members).not_to include household_member_youth
      expect(family_members).not_to include household_other_sektion_member
      expect(family_members).not_to include household_member_adult

      expect(family_members.count).to eq(3)
    end
  end

  context "#main_person" do
    it "finds person with family_main_person set" do
      expect(adult.sac_family_main_person).to be true # check assumption

      expect(child.sac_family.main_person).to eq adult
    end
  end

  context "#adult_family_members" do
    it { expect(adult.sac_family.adult_family_members).to contain_exactly(adult, adult2) }
  end

  context "#housemates" do
    it do
      expect(adult.sac_family.housemates).to contain_exactly(
        adult,
        adult2,
        child,
        household_member_youth,
        household_other_sektion_member,
        household_member_adult
      )
    end
  end

  context "#non_family_housemates" do
    it do
      expect(adult.sac_family.non_family_housemates).to contain_exactly(
        household_member_youth,
        household_other_sektion_member,
        household_member_adult
      )
    end
  end

  context "#member?" do
    it "is never a family member if not in a household" do
      expect(people(:mitglied).sac_family.member?).to eq(false)
    end

    it "is not a family member if in same household but other sektion" do
      expect(household_other_sektion_member.sac_family.member?).to eq(false)
    end

    it "is not a family member if in same household but youth mitglied" do
      expect(household_member_youth.sac_family.member?).to eq(false)
    end

    it "is family member" do
      [adult, adult2, child].each do |p|
        expect(p.sac_family.member?).to eq(true)
      end
    end
  end

  context "#id" do
    it "returns prefixed household_key for family member" do
      expect(adult.family_id).to eq "F#{adult.household_key}"
    end

    it "does not prefix household_key if already prefixed" do
      adult.household_key = "F42"
      expect(adult.family_id).to eq "F42"
    end

    it "returns nil for non family member" do
      expect(household_member_youth.family_id).to be_nil
    end
  end

  context "#update!" do
    before { freeze_time }

    let!(:family_head) { Fabricate(:person, household_key: "this-household", birthday: today - 40.years, sac_family_main_person: true) }

    subject { described_class.new(family_head) }

    {
      Group::SektionsMitglieder::Mitglied => :bluemlisalp_mitglieder,
      Group::SektionsNeuanmeldungenSektion::Neuanmeldung => :bluemlisalp_neuanmeldungen_sektion,
      Group::SektionsNeuanmeldungenNv::Neuanmeldung => :bluemlisalp_neuanmeldungen_nv
    }.each do |type, group|
      context type.sti_name.to_s do
        let!(:role) do
          type.create!(
            group: groups(group),
            person: family_head,
            created_at: Date.current.beginning_of_year,
            delete_on: Date.current.end_of_year
          )
        end

        it "adds role to non-family household members of family age" do
          adult = Fabricate(:person, household_key: family_head.household_key, birthday: today - 30.years)
          child = Fabricate(:person, household_key: family_head.household_key, birthday: today - 10.years)

          expect { subject.update! }
            .to change { Role.count }.by(2)
            .and change { type.count }.by(2)
            .and change { adult.roles.count }.by(1)
            .and change { child.roles.count }.by(1)

          specimen = adult.roles.last
          expect(specimen.attributes).to include(role.attributes.slice(
            "type", "group_id", "delete_on"
          ))
          expect(specimen.created_at).to eq Time.current
        end

        it "does not add role to youth household members" do
          person = Fabricate(:person, household_key: family_head.household_key, birthday: today - 19.years)
          expect { subject.update! }.not_to change { person.roles.count }
        end

        it "does not add role to person without birthday" do
          person = Fabricate(:person, household_key: family_head.household_key, birthday: nil)
          expect { subject.update! }.not_to change { person.roles.count }
        end

        it "does not add role to adult if family already has 2 adults" do
          second_family_adult = Fabricate(:person, household_key: family_head.household_key, birthday: today - 30.years)
          role.dup.tap do |r|
            r.person = second_family_adult
            r.created_at = role.created_at
          end.save!

          person = Fabricate(:person, household_key: adult.household_key, birthday: today - 30.years)
          expect { adult.sac_family.update! }.not_to change { person.roles.count }
        end

        it "adds roles even when initiated on non-family household member" do
          non_family_person = Fabricate(:person, household_key: family_head.household_key, birthday: today - 30.years)

          expect { non_family_person.sac_family.update! }.to change { non_family_person.roles.count }.by(1)
          specimen = non_family_person.roles.last
          expect(specimen.attributes).to include(role.attributes.slice(
            "type", "group_id", "delete_on"
          ))
        end
      end
    end

    {
      Group::SektionsMitglieder::MitgliedZusatzsektion => :matterhorn_mitglieder,
      Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion => :matterhorn_neuanmeldungen_sektion,
      Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion => :matterhorn_neuanmeldungen_nv
    }.each do |type, group|
      context type.sti_name.to_s do
        let!(:stammsektion_role) do
          Group::SektionsMitglieder::Mitglied.create!(
            group: groups(:bluemlisalp_mitglieder),
            person: family_head,
            created_at: Date.current.beginning_of_year,
            delete_on: Date.current.end_of_year
          )
        end

        let!(:role) do
          type.create!(
            group: groups(group),
            person: family_head,
            created_at: Date.current.beginning_of_year,
            delete_on: Date.current.end_of_year
          )
        end

        it "adds role to non-family household members of family age" do
          adult = Fabricate(:person, household_key: family_head.household_key, birthday: today - 30.years)
          child = Fabricate(:person, household_key: family_head.household_key, birthday: today - 10.years)

          expect { subject.update! }
            .to change { Role.count }.by(4) # including the stammsektion roles and zusatzsektion roles
            .and change { type.count }.by(2)
            .and change { adult.roles.count }.by(2) # 1 stammsektion and 1 zusatzsektion
            .and change { child.roles.count }.by(2) # 1 stammsektion and 1 zusatzsektion

          specimen = type.find_by(person_id: adult.id)
          expect(specimen.attributes).to include(role.attributes.slice(
            "type", "group_id", "delete_on"
          ))
          expect(specimen.created_at).to eq Time.current
        end

        it "does not add role to youth household members" do
          person = Fabricate(:person, household_key: family_head.household_key, birthday: today - 19.years)
          expect { subject.update! }.not_to change { person.roles.count }
        end

        it "does not add role to person without birthday" do
          person = Fabricate(:person, household_key: family_head.household_key, birthday: nil)
          expect { subject.update! }.not_to change { person.roles.count }
        end

        it "does not add role to adult if family already has 2 adults" do
          second_family_adult = Fabricate(:person, household_key: family_head.household_key, birthday: today - 30.years)
          stammsektion_role.dup.tap do |r|
            r.person = second_family_adult
            r.created_at = stammsektion_role.created_at
          end.save!

          person = Fabricate(:person, household_key: adult.household_key, birthday: today - 30.years)
          expect { adult.sac_family.update! }.not_to change { person.roles.count }
        end

        it "adds multiple zusatzsektion roles" do
          other_sektion_mitglieder = Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023)
            .children.find_by(type: Group::SektionsMitglieder)

          Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
            group: other_sektion_mitglieder,
            person: family_head,
            created_at: Date.current.beginning_of_year,
            delete_on: Date.current.end_of_year
          )

          housemate = Fabricate(:person, household_key: family_head.household_key, birthday: today - 30.years)

          expect { subject.update! }
            .to change { Role.count }.by(3) # including the stammsektion roles and 2 zusatzsektion roles
            .and change { housemate.roles.count }.by(3) # 1 stammsektion and 2 zusatzsektion

          expect(housemate.roles.pluck(:group_id, :type)).to contain_exactly(
            [groups(:bluemlisalp_mitglieder).id, Group::SektionsMitglieder::Mitglied.sti_name],
            [other_sektion_mitglieder.id, Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name],
            [groups(group).id, type.sti_name]
          )
        end

        it "adds roles even when initiated on non-family household member" do
          non_family_person = Fabricate(:person, household_key: family_head.household_key, birthday: today - 30.years)

          expect { non_family_person.sac_family.update! }.to change { non_family_person.roles.count }.by(2)
          specimen = non_family_person.roles.find_by(type: type.sti_name)
          expect(specimen.attributes).to include(role.attributes.slice(
            "type", "group_id", "delete_on"
          ))
        end
      end
    end
  end
end
