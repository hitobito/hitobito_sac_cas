# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Role do
  let(:person) { Fabricate(:person) }
  let(:bluemlisalp_mitglieder) { groups(:bluemlisalp_mitglieder) }
  let(:bluemlisalp_neuanmeldungen_nv) { groups(:bluemlisalp_neuanmeldungen_nv) }
  let(:bluemlisalp_neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }

  context "Mitglied vs. Beitragskategorie" do
    it "assigns correct beitragskategorie when creating new mitglied role" do
      person.update!(birthday: Time.zone.today - 17.years)

      role = Fabricate(Group::SektionsMitglieder::Mitglied.name,
        person: person,
        group: bluemlisalp_mitglieder)

      expect(role.beitragskategorie).to eq("youth")
    end

    it "is not valid without person's birthdate" do
      person.update!(birthday: nil)
      role = Fabricate.build(Group::SektionsMitglieder::Mitglied.name,
        person: person,
        group: bluemlisalp_mitglieder)

      expect(role).not_to be_valid
    end

    it "assigns correct beitragskategorie when creating new neuanmeldung role" do
      person.update!(birthday: Time.zone.today - 17.years)

      neuanmeldung_nv =
        Fabricate.build(Group::SektionsNeuanmeldungenNv::Neuanmeldung.name,
          person: person, group: bluemlisalp_neuanmeldungen_nv).tap(&:validate)

      expect(neuanmeldung_nv.beitragskategorie).to eq("youth")

      neuanmeldung_sektion = Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.name,
        person: person,
        group: bluemlisalp_neuanmeldungen_sektion).tap(&:validate)

      expect(neuanmeldung_sektion.beitragskategorie).to eq("youth")
    end

    it "is not valid without person's birthdate" do
      person.update!(birthday: nil)
      neuanmeldung_nv =
        Fabricate.build(Group::SektionsNeuanmeldungenNv::Neuanmeldung.name,
          person: person, group: bluemlisalp_neuanmeldungen_nv)

      expect(neuanmeldung_nv).not_to be_valid

      neuanmeldung_sektion =
        Fabricate.build(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.name,
          person: person, group: bluemlisalp_neuanmeldungen_sektion)

      expect(neuanmeldung_sektion).not_to be_valid
    end
  end

  describe "minimum age validation" do
    [
      [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder],
      [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion],
      [Group::SektionsNeuanmeldungenNv::Neuanmeldung, :bluemlisalp_neuanmeldungen_nv]
    ].each do |role_type, group|
      it "does not accept person without birthday for #{role_type}" do
        person.birthday = nil
        role = Fabricate.build(role_type.name, person: person, group: groups(group))
        expect(role).not_to be_valid
        expect(role.errors[:person])
          .to include("muss ein Geburtsdatum haben und mindestens 6 Jahre alt sein")
      end

      it "accepts person exceeding age restriction for #{role_type}" do
        person.birthday = 6.years.ago - 1.day
        role = Fabricate.build(role_type.name, person: person, group: groups(group),
          beitragskategorie: :adult)
        expect(role).to be_valid
      end

      it "rejects person below age restriction for #{role_type}" do
        person.birthday = 5.years.ago
        role = Fabricate.build(role_type.name, person: person, group: groups(group),
          beitragskategorie: :adult)
        expect(role).not_to be_valid
        expect(role.errors[:person])
          .to include("muss ein Geburtsdatum haben und mindestens 6 Jahre alt sein")
      end
    end

    it "accepts person below age limit on other group" do
      person.birthday = 5.years.ago
      role = Fabricate.build(Group::Geschaeftsstelle::Admin.name,
        person: person,
        group: groups(:geschaeftsstelle))
      expect(role).to be_valid
    end
  end

  describe "family members validation" do
    [
      [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder],
      [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion],
      [Group::SektionsNeuanmeldungenNv::Neuanmeldung, :bluemlisalp_neuanmeldungen_nv]
    ].each do |role_type, group|
      context "for #{role_type}" do
        let(:role_type) { role_type }
        let(:group) { group }

        def build_role(age: 23, beitragskategorie: :family, household_key: "household42", family_main_person: false)
          person = Fabricate.build(:person,
            birthday: age.years.ago,
            household_key: household_key,
            sac_family_main_person: family_main_person).tap(&:save!)
          role = Fabricate.build(role_type.name, person: person, group: groups(group),
            beitragskategorie: beitragskategorie)
          person.primary_group = role.group
          role
        end

        it "beitragskategorie=family is accepted on primary group" do
          role = build_role(family_main_person: true)
          role.person.primary_group = role.group

          expect(role).to be_valid
        end

        it "beitragskategorie=family is accepted on non-primary group" do
          role = build_role(family_main_person: true)
          role.person.primary_group = groups(:geschaeftsstelle)

          expect(role).to be_valid
        end

        context "adult family members count" do
          context "with beitragskategorie=family" do
            it "accepts single adult person in household" do
              expect(build_role(family_main_person: true)).to be_valid
            end

            it "accepts second adult person in same household" do
              # Add 1 adult
              build_role(family_main_person: true).save!

              # Test second adult
              expect(build_role).to be_valid
            end

            it "rejects third adult person in same household" do
              # Add 2 adults
              build_role(family_main_person: true).save!
              build_role.save!

              # Test third adult
              third_adult = build_role
              expect(third_adult).not_to be_valid
              expect(third_adult.errors[:base])
                .to include("In einer Familienmitgliedschaft sind maximal 2 Erwachsene inbegriffen.")
            end

            it "accepts third adult person in same household with non-default context" do
              # Add 2 adults
              build_role(family_main_person: true).save!
              build_role.save!

              # Test third adult
              third_adult = build_role
              expect(third_adult).to be_valid(:import)
            end

            it "accepts third youth person in same household" do
              # Add 2 adults
              build_role(family_main_person: true).save!
              build_role.save!
              # and 2 youth
              2.times { build_role(age: 17, beitragskategorie: :youth).save! }

              # Test third youth
              third_youth = build_role(age: 17)
              expect(third_youth).to be_valid
            end

            it "accepts third adult in different household" do
              # Add 2 adults
              build_role(household_key: "1stHousehold", family_main_person: true).save!
              build_role(household_key: "1stHousehold").save!

              # Test third adult in different household
              third_adult = build_role(household_key: "2ndHousehold", family_main_person: true)
              expect(third_adult).to be_valid
            end
          end

          context "with beitragskategorie=adult" do
            it "accepts third adult in same household" do
              # Add 2 adults with beitragskategorie=family
              build_role(beitragskategorie: :family, family_main_person: true).save!
              build_role(beitragskategorie: :family).save!

              # Test third adult with beitragskategorie=adult
              # This is a special case, because the person is part of the same household, but
              # is not included in the family membership.
              third_adult = build_role(beitragskategorie: :adult)
              expect(third_adult).to be_valid
            end
          end
        end

        context "family main person" do
          context "with beitragskategorie=family" do
            it "is valid if own person is solo main person" do
              expect(build_role(family_main_person: true)).to be_valid
            end

            it "is valid if other family member is solo main person" do
              build_role(family_main_person: true).save!
              expect(build_role(family_main_person: false)).to be_valid
            end

            it "is invalid if no other family member is main person" do
              role = build_role(family_main_person: false)
              expect(role).to be_invalid
              expect(role.errors.errors).to include(have_attributes(attribute: :base, type: :must_have_one_family_main_person_in_family))

              build_role(family_main_person: false).save(validate: false) # skip validations as it would be invalid

              expect(role).to be_invalid
              expect(role.errors.errors).to include(have_attributes(attribute: :base, type: :must_have_one_family_main_person_in_family))
            end

            it "is invalid when main person if other family member is also main person" do
              build_role(family_main_person: true).save!

              role = build_role(family_main_person: true)
              expect(role).to be_invalid
              expect(role.errors.errors).to include(have_attributes(attribute: :base, type: :must_have_one_family_main_person_in_family))
            end

            it "is invalid if more than one other family member are main person" do
              build_role(family_main_person: true).save!
              build_role(family_main_person: true).save(validate: false) # skip validations as it would be invalid

              role = build_role(family_main_person: false)
              expect(role).to be_invalid
              expect(role.errors.errors).to include(have_attributes(attribute: :base, type: :must_have_one_family_main_person_in_family))
            end
          end

          context "with beitragskategorie=adult" do
            it "ignores attribute" do
              role = build_role(family_main_person: false, beitragskategorie: :adult)
              expect(role).to be_valid

              role.person.sac_family_main_person = true
              expect(role).to be_valid

              build_role(family_main_person: true, beitragskategorie: :adult).save!
              build_role(family_main_person: false, beitragskategorie: :adult).save!
              expect(role).to be_valid
            end
          end
        end
      end
    end
  end

  describe "primary_group" do
    let(:funktionaere) { groups(:bluemlisalp_funktionaere) }
    let(:primary) { groups(:geschaeftsstelle) }
    let(:mitglieder) { groups(:bluemlisalp_mitglieder) }

    context "with primary_group not a preferred_primary" do
      let(:person) { people(:admin) }

      it "does not change when creating normal role" do
        expect do
          Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name, group: funktionaere,
            person: person)
        end.not_to(change { person.reload.primary_group })
      end

      it "does change when creating preferred role" do
        expect do
          Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
            group: mitglieder,
            person: person, beitragskategorie: :adult)
        end.to change { person.reload.primary_group }.from(primary).to(mitglieder)
      end

      it "does change back when destroying preferred role" do
        role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
          group: mitglieder,
          person: person, beitragskategorie: :adult)
        expect do
          role.destroy
        end.to change { person.reload.primary_group }.from(mitglieder).to(primary)
      end
    end

    context "with primary_group a preferred_primary" do
      let(:person) { people(:mitglied) }

      it "does not change when creating normal role" do
        expect do
          Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name,
            group: funktionaere,
            person: person)
        end.not_to(change { person.reload.primary_group })
      end

      it "does not change when creating preferred role" do
        other = Fabricate(Group::Sektion.sti_name, parent: groups(:root),
          foundation_year: 2023).children
          .find_by(type: Group::SektionsMitglieder.sti_name)
        expect do
          Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
            group: other,
            person: person,
            beitragskategorie: :adult,
            start_on: person.sac_membership.stammsektion_role.end_on + 1.day,
            end_on: person.sac_membership.stammsektion_role.end_on + 1.year)
        end.not_to(change { person.reload.primary_group })
      end
    end
  end

  describe "#to_s" do
    let(:person) { people(:mitglied) }

    it "includes the beitragskategorie label" do
      expect(roles(:mitglied).to_s).to eq "Mitglied (Stammsektion) (Einzel)"
    end
  end

  context "#membership_years" do
    let(:start_on) { Date.parse("01-01-2000") }
    let(:end_on) { start_on + 7.years + 6.months }
    let(:years) { 7.5 }

    def create_role(**attrs)
      Fabricate(Group::SektionsMitglieder::Mitglied.name,
        group: groups(:bluemlisalp_mitglieder),
        person: person,
        **attrs.reverse_merge(start_on: start_on)).then do |role|
        Role.with_inactive.with_membership_years.find_by(id: role.id)
      end
    end

    it "raises error when not using scope :with_membership_years" do
      create_role(end_on: end_on)
      expect { person.reload.roles.with_inactive.first.membership_years }
        .to raise_error(RuntimeError, /use Role scope :with_membership_years/)
    end

    it "calculates value for role with end_on" do
      role = create_role(end_on: end_on)
      expect(role.membership_years).to be_within(0.01).of(years)
    end

    it "calculates value for archived_role" do
      role = create_role(archived_at: end_on)
      expect(role.membership_years).to be_within(0.01).of(years)
    end

    it "calculates value up to now" do
      role = create_role(start_on: 1.year.ago, end_on: 10.years.from_now)

      expect(role.membership_years).to be_within(0.01).of(1.0)
    end

    it "does not count future years" do
      role = create_role(start_on: 1.year.from_now, end_on: 2.years.from_now)
      expect(role.membership_years).to eq 0
    end

    (SacCas::MITGLIED_ROLES - [Group::SektionsMitglieder::Mitglied]).each do |role_type|
      it "returns 0 for #{role_type.sti_name}" do
        role = create_role(end_on: end_on)
        person.roles.with_inactive.update_all(type: role_type.sti_name)
        role = person.roles.with_inactive.with_membership_years.find_by(id: role.id)
        expect(role.class).to eq role_type
        expect(role.membership_years).to eq 0
      end
    end
  end

  context "#end_on" do
    subject(:role) do
      person.roles.new(
        type: role_type.name,
        group: bluemlisalp_neuanmeldungen_nv,
        start_on: Time.zone.today
      )
    end

    context "neuanmeldung role" do
      let(:role_type) { Group::SektionsNeuanmeldungenNv::Neuanmeldung }

      it "is valid without end_on" do
        expect(role).to be_valid
      end
    end

    context "other role" do
      let(:role_type) { Group::SektionsMitglieder::Mitglied }

      it "is invalid without end_on" do
        expect(role).not_to be_valid
      end
    end
  end

  context "#termination_reason_text" do
    let(:role) { roles(:mitglied) }

    it "returns nil if no termination_reason" do
      expect(role.termination_reason_text).to be_nil
    end

    it "returns termination_reason label" do
      role.termination_reason = Fabricate(:termination_reason, text: "Sonstiger Grund")
      expect(role.termination_reason_text).to eq "Sonstiger Grund"
    end
  end

  context "#beitragskategorie" do
    it "returns beitragskategorie as string active support string inquirer" do
      role = roles(:mitglied)
      expect(role.beitragskategorie.class).to eq(ActiveSupport::StringInquirer)
    end

    it "returns empty string if beitragskategorie is nil" do
      role = roles(:abonnent_alpen)
      expect(role.beitragskategorie).to be_nil
    end
  end
end
