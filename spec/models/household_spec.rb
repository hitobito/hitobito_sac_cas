# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Household do
  def create_role(key, role, owner: person, **attrs)
    group = key.is_a?(Group) ? key : groups(key)
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group: group, person: owner, **attrs)
  end
  let(:bluemlisalp_mitglieder) { groups(:bluemlisalp_mitglieder) }

  let(:person) { Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied", email: "dad@hitobito.example.com", confirmed_at: Time.current, birthday: Date.new(2000, 1, 1)) }
  let(:adult) { Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied", birthday: Date.new(1999, 10, 5)) }
  let(:child) { Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied", birthday: Date.new(2012, 9, 23)) }
  let(:second_child) { Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied", birthday: Date.new(2014, 4, 13)) }
  let(:second_adult) { Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied", birthday: Date.new(1998, 11, 6)) }

  subject!(:household) { Household.new(person, maintain_sac_family: false) }

  def sequence = Sequence.by_name(SacCas::Household::HOUSEHOLD_KEY_SEQUENCE)

  before do
    travel_to(Date.new(2024, 5, 31))
  end

  def add_and_save(*members)
    members.each { |member| household.add(member) }
    expect(household.save).to eq(true), household.errors.full_messages.join(", ")
  end

  def remove_and_save(*members)
    members.each { |member| household.remove(member) }
    expect(household.save).to eq true
  end

  it "uses sequence for household key" do
    # Begin with counting sequence
    Sequence.increment!(SacCas::Household::HOUSEHOLD_KEY_SEQUENCE)

    expect do
      household = adult.household
      household.add(child)
      household.save!
    end.to change { Sequence.current_value(SacCas::Household::HOUSEHOLD_KEY_SEQUENCE) }.by(1)
    expect(adult.reload.household_key).to eq Sequence.current_value(SacCas::Household::HOUSEHOLD_KEY_SEQUENCE).to_s
  end

  describe "validations" do
    it "is invalid if it contains no adult person" do
      household = Household.new(child)
      household.add(second_child)
      expect(household.valid?).to eq false
      expect(household.errors[:base]).to match_array(["Der Haushalt enthält keine erwachsene Person mit E-Mail Adresse.",
        "Eine Familie muss mindestens 1 erwachsene Person enthalten."])
    end

    it "is invalid if it contains more than two adult people" do
      household.add(adult)
      household.add(second_adult)
      expect(household.valid?).to eq false
      expect(household.errors[:base]).to match_array(["Eine Familie darf höchstens 2 erwachsene Personen enthalten."])
    end

    it "is invalid if it contains only one person" do
      household = Household.new(person)
      expect(household.valid?).to eq false
      expect(household.errors[:base]).to match_array(["Eine Familie muss mindestens 2 Personen enthalten."])
    end

    it "is valid if pending removed person does not have a confirmed email" do
      add_and_save(adult, child)
      adult.update_attribute(:confirmed_at, nil)
      household.remove(adult)
      expect(household.valid?).to eq true
    end

    it "is valid if it contains no adult with confirmed email" do
      adult.update_attribute(:confirmed_at, nil)
      household = Household.new(adult)
      household.add(child)
      expect(household.valid?).to eq true
    end

    it "is valid in destroy context with blank email" do
      person.email = nil

      expect(household.valid?(:destroy)).to eq true
    end

    it "is invalid if no household person has a membership role" do
      new_person = Fabricate(
        :person_with_role,
        group: groups(:abo_die_alpen),
        role: Group::AboMagazin::Abonnent.sti_name,
        beitragskategorie: :adult
      )
      other_household_person = Fabricate(
        :person_with_role,
        group: groups(:abo_die_alpen),
        role: Group::AboMagazin::Abonnent.sti_name,
        beitragskategorie: :adult
      )
      household = Household.new(new_person)
      household.add(other_household_person)
      expect(household.valid?).to eq false
      expect(household.errors[:members]).to match_array(["Mindestens eine Person in der Familie muss bereits SAC Mitglied sein."])
    end

    it "is invalid if no person has a membership at all" do
      new_person = Fabricate(:person)
      other_household_person = Fabricate(:person)
      household = Household.new(new_person)
      household.add(other_household_person)
      expect(household.valid?).to eq false
      expect(household.errors[:members]).to match_array(["Mindestens eine Person in der Familie muss bereits SAC Mitglied sein."])
    end

    it "is invalid if a person has a terminated membership" do
      new_person = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
        group: groups(:bluemlisalp_mitglieder),
        beitragskategorie: :adult,
        created_at: 1.year.ago,
        start_on: 1.year.ago).person
      other_household_person = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
        group: groups(:bluemlisalp_mitglieder),
        beitragskategorie: :adult,
        created_at: 1.year.ago,
        start_on: 1.year.ago).person
      Roles::Termination.new(role: other_household_person.roles.first, terminate_on: 1.day.from_now).call
      household = Household.new(new_person)
      household.add(other_household_person)
      expect(household.valid?).to eq false
      expect(household.errors.full_messages.first).to include("#{other_household_person.full_name} hat einen Austritt geplant.")
    end
  end

  describe "maintaining sac_family" do
    context "when enabled" do
      subject(:household) { Household.new(person, maintain_sac_family: true) }

      it "mutates memberships" do
        expect do
          Household.new(person, maintain_sac_family: true).add(adult).save!
        end
          .to change { person.sac_membership.stammsektion_role.beitragskategorie }.from("adult").to("family")
          .and change { adult.sac_membership.stammsektion_role.beitragskategorie }.from("adult").to("family")
      end

      it "makes reference person main person for new household" do
        person.update!(birthday: 23.years.ago)
        adult.update!(birthday: 24.years.ago)
        expect do
          household.add(adult).save!
        end.to change { person.sac_family_main_person }.from(false).to(true)
      end

      it "makes oldest person main person for existing household" do
        household.add(child)
        household.save!

        person.update!(birthday: 23.years.ago)
        adult.update!(birthday: 24.years.ago)
        expect do
          household.remove(person)
          household.add(adult)
          household.save!
        end.to change { adult.sac_family_main_person }.from(false).to(true)
          .and change { person.sac_family_main_person }.from(true).to(false)
      end

      it "calls Memberships::FamilyMutation#join! for added person" do
        # prepare a family
        household.add(child).save!
        household.reload

        expect(Memberships::FamilyMutation).to receive(:new).with(adult) do
          instance_double(Memberships::FamilyMutation).tap { expect(_1).to receive(:join!).with(household.reference_person) }
        end

        household.add(adult).save!
      end

      it "calls Memberships::FamilyMutation#leave! for removed person" do
        # prepare a family
        household.add(child).add(second_adult).save!
        household.reload

        expect(Memberships::FamilyMutation).to receive(:new).with(second_adult) do
          instance_double(Memberships::FamilyMutation).tap { expect(_1).to receive(:leave!) }
        end

        household.remove(second_adult).save!
      end

      it "updates family main person flag" do
        # prepare a family
        household.add(child).add(second_adult).save!
        household.reload

        expect(household.main_person).to be_present
        original_main_person = household.main_person

        expect do
          household.remove(original_main_person).save!
        end
          .to change { household.main_person }.from(original_main_person)
      end

      it "clears family main person flag from removed person" do
        # prepare a family
        household.add(child).add(second_adult).save!
        household.reload

        original_main_person = household.main_person

        expect do
          household.remove(original_main_person).save!
        end
          .to change { original_main_person.reload.sac_family_main_person }.from(true).to(false)
      end

      it "can create and dissolve family on the same day repeatedly" do
        person = people(:mitglied)
        housemate = Fabricate(:person)

        expect { Household.new(person, maintain_sac_family: true).add(housemate).save! }
          .to change { person.reload.household_key }.from(nil)
          .and change { person.sac_family_main_person }.to(true)
          .and change { housemate.reload.household_key }.from(nil)

        expect { person.household.destroy }
          .to change { person.reload.household_key }.to(nil)
          .and change { person.sac_family_main_person }.to(false)
          .and change { housemate.reload.household_key }.to(nil)

        expect { Household.new(person, maintain_sac_family: true).add(housemate).save! }
          .to change { person.reload.household_key }.from(nil)
          .and change { person.sac_family_main_person }.to(true)
          .and change { housemate.reload.household_key }.from(nil)
      end

      context "creates papertrail versions for changes of main person flag", versioning: true do
        # count the versions of the person where the main person flag was changed to the given value
        def main_person_versions_count(person, target_value = true)
          person.versions.count do |v|
            v.object_changes.start_with?("---") &&
              v.changeset.dig("sac_family_main_person", 1) == target_value
          end
        end

        it "when creating household" do
          expect { household.add(child).save! }
            .to change { person.reload.sac_family_main_person }.from(false).to(true)
            .and change { main_person_versions_count(person) }.from(0).to(1)
        end

        it "when removing main person from household" do
          person.household.add(adult).add(child).save!

          expect { person.household.remove(person).save! }
            .to change { person.reload.sac_family_main_person }.from(true).to(false)
            .and change { main_person_versions_count(person, false) }.from(0).to(1)
        end

        it "when adding new main person to household" do
          person.household.add(child).save!
          new_main_person = adult

          expect { child.household.remove(person).add(new_main_person).save! }
            .to change { new_main_person.reload.sac_family_main_person }.from(false).to(true)
            .and change { main_person_versions_count(new_main_person) }.from(0).to(1)
        end
      end
    end

    context "when disabled" do
      subject(:household) { Household.new(person, maintain_sac_family: false) }

      it "does not mutate memberships if told to skip" do
        expect do
          Household.new(person, maintain_sac_family: false).add(adult).save!
        end
          .to not_change { person.sac_membership.stammsektion_role.attributes }
          .and not_change { adult.sac_membership.stammsektion_role.attributes }
      end

      it "does not call Memberships::Family" do
        # prepare a family
        household.add(child).add(second_adult).save!
        household.reload

        expect(Memberships::FamilyMutation).not_to receive(:new)

        expect do
          household.remove(second_adult).save!
        end
          .to not_change { second_adult.sac_membership.stammsektion_role.attributes }
          .and not_change { second_adult.sac_membership.stammsektion_role.attributes }
      end
    end
  end

  describe "people manager relations" do
    context "adding people" do
      it "noops when adding adult" do
        expect { add_and_save(adult) }.not_to(change { PeopleManager.count })
      end

      it "noops if relation exists" do
        person.people_manageds.create!(managed: child)
        expect { add_and_save(child) }.not_to(change { PeopleManager.count })
      end

      it "creates relation" do
        expect { add_and_save(child) }.to change { PeopleManager.count }.by(1)
        expect(person.manageds).to eq [child]
        expect(child.managers).to eq [person]
      end

      it "creates only missing relations" do
        person.people_manageds.create!(managed: child)
        expect { add_and_save(child, second_child) }.to change { PeopleManager.count }.by(1)
        expect(person.manageds).to match_array([child, second_child])
        expect(child.managers).to eq [person]
        expect(second_child.managers).to eq [person]
      end

      it "creates multiple relations for child" do
        person.people_manageds.create!(managed: child)
        expect { add_and_save(child, adult) }.to change { PeopleManager.count }.by(1)
        expect(child.managers).to match_array([person, adult])
      end

      it "noops and raises if error occurs" do
        expect(PeopleManager).to receive(:create!).once.and_call_original
        expect(PeopleManager).to receive(:create!).and_raise("ouch")
        expect do
          add_and_save(child, second_child)
        end.to raise_error("ouch").and(not_change { PeopleManager.count })
      end
    end

    context "removing people" do
      it "removes single relation" do
        add_and_save(adult, child)
        expect { remove_and_save(adult) }.to change { PeopleManager.count }.by(-1)
      end

      it "removes multiple relations" do
        add_and_save(adult, child, second_child)
        expect { remove_and_save(adult, child) }.to change { PeopleManager.count }.by(-3)
        expect(person.manageds).to eq [second_child]
        expect(second_child.managers).to eq [person]
        expect(adult.reload.manageds).to be_empty
        expect(child.reload.managers).to be_empty
      end
    end

    describe "destroying household" do
      it "removes relation" do
        add_and_save(child)
        expect { household.destroy }.to change { PeopleManager.count }.by(-1)
      end

      it "removes relations" do
        add_and_save(adult, child, second_child)
        expect { household.destroy }.to change { PeopleManager.count }.by(-4)
      end

      it "noops and raises when error occurs" do
        add_and_save(child)
        expect_any_instance_of(Person).to receive(:managers).and_raise("ouch")
        expect { household.destroy }.to raise_error("ouch").and(not_change { PeopleManager.count })
      end

      context "maintain_sac_family" do
        subject!(:household) { Household.new(person, maintain_sac_family: true) }

        it "succeeds with updating sac_family_main_person" do
          add_and_save(child)
          expect(person.reload).to be_sac_family_main_person
          expect { household.destroy }.to change { PeopleManager.count }.by(-1)
          expect(person.reload).not_to be_sac_family_main_person
        end
      end
    end
  end

  describe "#reload" do
    it "does not forget #maintain_sac_family value" do
      household = Household.new(person, maintain_sac_family: false)
      expect { household.reload }.not_to change { household.maintain_sac_family? }.from(false)

      household = Household.new(person, maintain_sac_family: true)
      expect { household.reload }.not_to change { household.maintain_sac_family? }.from(true)
    end
  end

  describe "overwrite address" do
    it "applies address for all members with invalid state when updating one person" do
      household.add(adult)
      adult.update_column(:street, nil)

      person.update!(street: "Langweilige Strasse")
      expect { household.save!(context: :update_address) }.not_to raise_error
      expect(household.members.map(&:person).map(&:street)).to all(eq("Langweilige Strasse"))
    end
  end
end
