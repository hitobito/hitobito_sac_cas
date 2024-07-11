# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe HouseholdMember do
  let(:person) { Fabricate(:person, email: "dad@hitobito.example.com", birthday: Date.new(2000, 1, 1)) }
  let(:household) { Household.new(person) }

  subject!(:household_member) { HouseholdMember.new(person, household) }

  before { travel_to(Date.new(2024, 5, 31)) }

  def create_mitglied_role(person, group: groups(:bluemlisalp_mitglieder), beitragskategorie: :adult)
    group = group.is_a?(Group) ? group : groups(group)
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
      beitragskategorie:,
      person:,
      group:)
  end

  describe "validations" do
    it "is invalid if member has different household key than reference person" do
      create_mitglied_role(person)
      other_household_person = Fabricate(:person, household_key: "OTHER_HOUSEHOLD_KEY")
      household_member = HouseholdMember.new(other_household_person, household)
      expect(household_member.valid?).to eq false
      expect(household_member.errors[:base]).to match_array(["#{other_household_person.full_name} kann nicht hinzugefügt werden, da die Person bereits einer anderen Familie zugeordnet ist."])
    end

    it "is invalid if birthday is blank" do
      create_mitglied_role(person)
      person.update_attribute(:birthday, nil)
      expect(household_member.valid?).to eq false
      expect(household_member.errors[:base]).to match_array(["#{person.full_name} hat kein Geburtsdatum."])
    end

    it "is invalid if birthday is below 6 years old" do
      create_mitglied_role(person)
      person.update_attribute(:birthday, Date.new(2019, 7, 20))
      expect(household_member.valid?).to eq false
      expect(household_member.errors[:base]).to match_array(["#{person.full_name} kann nicht hinzugefügt werden. Es sind nur Personen erlaubt im Alter von 6-17 oder ab 22 Jahren."])
    end

    it "is invalid if birthday is between 17 and 22 years old" do
      create_mitglied_role(person)
      person.update_attribute(:birthday, Date.new(2005, 7, 20))
      expect(household_member.valid?).to eq false
      expect(household_member.errors[:base]).to match_array(["#{person.full_name} kann nicht hinzugefügt werden. Es sind nur Personen erlaubt im Alter von 6-17 oder ab 22 Jahren."])
    end

    it "is invalid if member has different household key than reference person and has family sac membership" do
      other_household_person = Fabricate(:person, household_key: "OTHER_HOUSEHOLD_KEY", sac_family_main_person: true)
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
        beitragskategorie: :family,
        person: other_household_person,
        group: groups(:bluemlisalp_mitglieder))
      household_member = HouseholdMember.new(other_household_person, household)
      expect(household_member.valid?).to eq false
      expect(household_member.errors[:base]).to match_array(["#{other_household_person.full_name} kann nicht hinzugefügt werden, da die Person bereits einer anderen Familie zugeordnet ist."])
    end

    it "is invalid if member has sac membership in different section than reference person" do
      other_household_person = Fabricate(:person)
      create_mitglied_role(other_household_person, group: :bluemlisalp_mitglieder)
      create_mitglied_role(person, group: :matterhorn_mitglieder)
      household_member = HouseholdMember.new(other_household_person, household)
      expect(household_member.valid?).to eq false
      expect(household_member.errors[:base]).to match_array(["#{other_household_person.full_name} besitzt bereits eine Mitgliedschaft in einer anderen Sektion."])
    end

    context "with additional membership" do
      let(:other_household_person) { Fabricate(:person) }

      it "is valid if reference person has additional membership but person does not" do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
          beitragskategorie: :adult,
          person: other_household_person,
          group: groups(:bluemlisalp_mitglieder))
        Fabricate(Group::AboMagazin::Abonnent.sti_name.to_sym,
          beitragskategorie: :adult,
          person: person,
          group: groups(:abo_die_alpen))
        household_member = HouseholdMember.new(other_household_person, household)
        expect(household_member.valid?).to eq true
        expect(household_member.errors[:base]).not_to include("#{other_household_person.full_name} besitzt bereits eine Mitgliedschaft in einer anderen Sektion.")
      end

      it "is valid if household person has additional membership but reference person does not" do
        create_mitglied_role(person)
        Fabricate(Group::AboMagazin::Abonnent.sti_name.to_sym,
          beitragskategorie: :adult,
          person: other_household_person,
          group: groups(:abo_die_alpen))
        household_member = HouseholdMember.new(other_household_person, household)
        expect(household_member.valid?).to eq true
        expect(household_member.errors[:base]).not_to include("#{other_household_person.full_name} besitzt bereits eine Mitgliedschaft in einer anderen Sektion.")
      end
    end

    context "on destroy" do
      it "is valid if member has no confirmed email" do
        person.update_attribute(:email, "")
        expect(household_member.valid?(:destroy)).to eq true
      end

      it "is invalid if member has termination planned" do
        role = Fabricate.build(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
          beitragskategorie: :adult,
          person: person,
          end_on: 1.year.from_now,
          group: groups(:matterhorn_mitglieder))
        role.write_attribute(:terminated, true)
        role.save!

        expect(household_member.valid?(:destroy)).to eq false
        expect(household_member.errors[:base]).to match_array(["#{person.full_name} hat einen Austritt geplant."])
      end
    end
  end
end
