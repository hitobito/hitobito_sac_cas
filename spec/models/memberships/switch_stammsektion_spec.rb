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

    it "is valid with membership in different section" do
      create_role(:matterhorn_mitglieder, "Mitglied", created_at: 1.year.ago)
      expect(switch).to be_valid
    end

    describe "existing membership in tree" do
      describe "join section" do
        it "is invalid if person is join_section member" do
          create_role(:bluemlisalp_mitglieder, "Mitglied", created_at: 1.year.ago)
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
            created_at: 1.year.ago
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

    context "single person" do
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }
      let(:matterhorn_funktionaere) { groups(:matterhorn_funktionaere) }
      let!(:bluemlisalp_mitglied) do
        create_role(:bluemlisalp_mitglieder, "Mitglied", created_at: 1.year.ago)
      end
      let(:matterhorn_mitglied) { matterhorn_mitglieder.roles.find_by(person:) }

      it "creates new role and terminates existing" do
        expect do
          expect(switch.save).to eq true
        end.not_to(change { person.reload.roles.count })
        expect(bluemlisalp_mitglied.reload.deleted_at.utc.change(sec: 0))
          .to eq now.yesterday.end_of_day.utc.change(sec: 0)
        expect(matterhorn_mitglied.created_at).to eq now.to_s(:db)
        expect(matterhorn_mitglied.delete_on).to eq now.end_of_year.to_date
        expect(person.primary_group).to eq matterhorn_mitglieder
      end

      # NOTE - seems tricky because of nested transactions in common api
      # wait for https://github.com/hitobito/hitobito/issues/2775
      it "creates new role and destroys existing if not yet active" do
        bluemlisalp_mitglied.update_columns(created_at: 1.minute.ago)
        expect do
          expect(switch).to be_valid
          expect(switch.save).to eq true
        end.not_to(change { person.reload.roles.count })
        expect { bluemlisalp_mitglied.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(bluemlisalp_mitglied.reload.deleted_at).to eq now.yesterday.end_of_day.to_s(:db)
        expect(matterhorn_mitglied.created_at).to eq now.to_s(:db)
        expect(matterhorn_mitglied.delete_on).to eq now.end_of_year.to_date
        expect(person.primary_group).to eq matterhorn_mitglieder
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
          created_at: 1.year.ago
        )
        @bluemlisalp_mitglied_other = create_role(
          :bluemlisalp_mitglieder,
          "Mitglied",
          owner: other.reload,
          created_at: 1.year.ago
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

        expect(@bluemlisalp_mitglied.reload.deleted_at.change(sec: 0))
          .to eq now.yesterday.end_of_day.change(sec: 0)
        expect(@bluemlisalp_mitglied_other.reload.deleted_at.change(sec: 0))
          .to eq now.yesterday.end_of_day.change(sec: 0)
        expect(matterhorn_mitglied.created_at.change(sec: 0)).to eq now.change(sec: 0)

        expect(matterhorn_mitglied.delete_on).to eq now.end_of_year.to_date
        expect(matterhorn_mitglied_other.created_at.change(sec: 0)).to eq now.change(sec: 0)
        expect(matterhorn_mitglied_other.delete_on).to eq now.end_of_year.to_date
      end
    end
  end
end
