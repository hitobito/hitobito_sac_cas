# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::SwitchStammsektion do
  def create_role(key, role, owner: person, **attrs)
    group = key.is_a?(Group) ? key : groups(key)
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group:, person: owner, **attrs)
  end

  before { travel_to(now) }

  let(:now) { Time.zone.local(2024, 6, 19, 15, 33) }

  it "initialization fails on invalid group" do
    person = Fabricate(:person)
    expect do
      described_class.new(Group::Sektion.new, person)
    end.not_to raise_error

    expect do
      described_class.new(Group::Ortsgruppe.new, person)
    end.not_to raise_error

    expect do
      described_class.new(Group::SacCas.new, person)
    end.to raise_error("must be section/ortsgruppe")
  end

  subject(:switch) { described_class.new(join_section, person) }

  describe "validations" do
    let(:person) { Fabricate(:person) }
    let(:join_section) { groups(:bluemlisalp) }
    let(:errors) { switch.errors.full_messages }

    it "is invalid if person is not an sac member" do
      expect(switch).not_to be_valid
      expect(errors).to eq ["Person muss Sac Mitglied sein"]
    end

    context "with membership in different section" do
      let(:other_section) { groups(:matterhorn_mitglieder) }

      it "is valid if active since before today" do
        create_role(other_section, "Mitglied", start_on: 1.year.ago)
        expect(switch).to be_valid
      end

      it "is valid if active since today" do
        create_role(other_section, "Mitglied", start_on: Time.zone.today)

        # This recreates a bug that occured when the valid? method was run twice, resulting in the
        # @destroyed variable of of the roles_to_destroy roles being true on the second call and thus showing an unexpected error
        # because that variable impacted the role.delete call
        expect(switch).to be_valid
        expect(switch).to be_valid
      end

      it "is valid if family membership and active since today" do
        person.update!(sac_family_main_person: true, household_key: "family")
        other = Fabricate(:person, household_key: "family")

        opts = {beitragskategorie: "family", start_on: Time.zone.today}
        create_role(other_section, "Mitglied", **opts)
        create_role(other_section, "Mitglied", owner: other, **opts)

        expect(switch).to be_valid
      end
    end

    describe "existing membership in tree" do
      describe "join section" do
        it "is invalid if person is join_section member" do
          create_role(:bluemlisalp_mitglieder, "Mitglied", start_on: 1.year.ago)
          expect(switch).not_to be_valid
          expect(errors).to eq [
            "Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch"
          ]
        end
      end

      describe "ortsgruppe" do
        it "is valid if person is ortsgruppen member" do
          create_role(
            :bluemlisalp_ortsgruppe_ausserberg_mitglieder,
            "Mitglied",
            start_on: 1.year.ago
          )
          expect(switch).to be_valid
        end
      end
    end
  end

  describe "saving" do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:matterhorn) }
    let(:errors) { switch.errors.full_messages }

    subject(:switch) { described_class.new(group, person) }

    context "invalid" do
      it "save returns false and populates errors" do
        expect(switch.save).to eq false
        expect(switch.errors.full_messages).to eq ["Person muss Sac Mitglied sein"]
      end

      it "save! raises" do
        expect { switch.save! }.to raise_error(/cannot save invalid model/)
      end
    end

    shared_examples "can switch sektion on the same day repeatedly" do |person_fixture|
      it do
        # remove Zusatzsektion roles conflicting with the stammsektion switch
        Group::SektionsMitglieder::MitgliedZusatzsektion.delete_all

        person = people(person_fixture)
        described_class.new(groups(:matterhorn), person).save!
        expect(person.sac_membership.stammsektion).to eq groups(:matterhorn)

        described_class.new(groups(:bluemlisalp_ortsgruppe_ausserberg), person).save!
        expect(person.sac_membership.stammsektion).to eq groups(:bluemlisalp_ortsgruppe_ausserberg)

        described_class.new(groups(:matterhorn), person).save!
        expect(person.sac_membership.stammsektion).to eq groups(:matterhorn)

        described_class.new(groups(:bluemlisalp), person).save!
        expect(person.sac_membership.stammsektion).to eq groups(:bluemlisalp)
      end
    end

    context "single person" do
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }
      let(:matterhorn_funktionaere) { groups(:matterhorn_funktionaere) }
      let!(:bluemlisalp_mitglied) do
        create_role(:bluemlisalp_mitglieder, "Mitglied", start_on: 1.year.ago)
      end
      let(:matterhorn_mitglied) { matterhorn_mitglieder.roles.find_by(person:) }

      it "creates new role and terminates existing" do
        expect do
          expect(switch.save).to eq true
        end.not_to(change { person.reload.roles.count })
        expect(bluemlisalp_mitglied.reload.end_on).to eq now.to_date.yesterday
        expect(matterhorn_mitglied.start_on).to eq now.to_date
        expect(matterhorn_mitglied.end_on).to eq now.end_of_year.to_date
        expect(person.primary_group).to eq matterhorn_mitglieder
      end

      it "creates new role and destroys existing when start_on is today" do
        bluemlisalp_mitglied.update_column(:start_on, Time.zone.today)
        expect do
          expect(switch.save).to eq true
        end.not_to(change { person.reload.roles.count })
        expect { bluemlisalp_mitglied.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(matterhorn_mitglied.start_on).to eq now.to_date
        expect(matterhorn_mitglied.end_on).to eq now.end_of_year.to_date
        expect(person.primary_group).to eq matterhorn_mitglieder
      end

      it "creates new role and destroys existing if not yet active" do
        bluemlisalp_mitglied.update_columns(created_at: 1.minute.ago)
        expect do
          expect(switch).to be_valid
          expect(switch.save!).to eq true
        end.not_to(change { person.reload.roles.count })
        expect(matterhorn_mitglied.created_at).to eq now.to_fs(:db)
        expect(matterhorn_mitglied.end_on).to eq now.end_of_year.to_date
        expect(person.primary_group).to eq matterhorn_mitglieder
      end

      it_behaves_like "can switch sektion on the same day repeatedly", :mitglied

      it "can join family after switching sektion on the same day" do
        switch.save
        person.household.add(Fabricate(:person)).save!
        role = person.sac_membership.stammsektion_role
        expect(role).to be_family
        expect(role.group).to eq groups(:matterhorn_mitglieder)
      end

      it "can switch sektion after joining family on the same day" do
        person.household.add(Fabricate(:person)).save!
        switch.save
        role = person.sac_membership.stammsektion_role
        expect(role).to be_family
        expect(role.group).to eq groups(:matterhorn_mitglieder)
      end
    end

    context "family" do
      let(:other) { Fabricate(:person) }
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }
      let(:matterhorn_mitglied) { matterhorn_mitglieder.roles.find_by(person:) }
      let(:matterhorn_mitglied_other) { matterhorn_mitglieder.roles.find_by(person: other) }

      def create_sac_family(person, *others)
        person.update_column(:sac_family_main_person, true)
        # we set up roles manually, so disable `maintain_sac_family`
        household = Household.new(person, maintain_sac_family: false)
        others.each { |member| household.add(member) }
        household.save!
        person.reload
        others.each(&:reload)
      end

      before do
        @bluemlisalp_mitglied = create_role(
          :bluemlisalp_mitglieder,
          "Mitglied",
          start_on: 1.year.ago
        )
        @bluemlisalp_mitglied_other = create_role(
          :bluemlisalp_mitglieder,
          "Mitglied",
          owner: other.reload,
          start_on: 1.year.ago
        )
        create_sac_family(person, other)
        Role.where(id: [@bluemlisalp_mitglied.id,
          @bluemlisalp_mitglied_other.id]).update_all(beitragskategorie: :family)
      end

      it "is invalid if switch is attempted with person that is not a sac_family_main_person" do
        switch = described_class.new(group, other)
        expect(switch).not_to be_valid
        expect(switch.errors.full_messages).to include("Person muss Hauptperson der Familie sein")
      end

      it "creates new and terminates existing roles for each member" do
        expect do
          expect(switch.save!).to eq true
        end.not_to(change { Role.count })
        expect(@bluemlisalp_mitglied.reload.end_on).to eq now.yesterday.to_date
        expect(@bluemlisalp_mitglied_other.reload.end_on).to eq now.yesterday.to_date
        expect(matterhorn_mitglied.start_on).to eq now.to_date
        expect(matterhorn_mitglied.end_on).to eq now.end_of_year.to_date
        expect(matterhorn_mitglied_other.start_on).to eq now.to_date
        expect(matterhorn_mitglied_other.end_on).to eq now.end_of_year.to_date
      end

      it_behaves_like "can switch sektion on the same day repeatedly", :familienmitglied

      it "can leave family after switching sektion on the same day" do
        switch.save!
        person.household.destroy
        role = person.sac_membership.stammsektion_role
        expect(role).to be_adult
        expect(role.group).to eq groups(:matterhorn_mitglieder)
      end

      it "can switch sektion after leaving family on the same day" do
        person.household.destroy
        switch.save!
        role = person.sac_membership.stammsektion_role
        expect(role).to be_adult
        expect(role.group).to eq groups(:matterhorn_mitglieder)
      end
    end
  end
end
