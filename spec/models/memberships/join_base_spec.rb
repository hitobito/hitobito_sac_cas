# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::JoinBase do
  def create_role(key, role, owner: person, **attrs)
    group = key.is_a?(Group) ? key : groups(key)
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group: group, person: owner, **attrs)
  end

  it "initialization fails on invalid group" do
    expect { described_class.new(Group::Sektion.new, :person) }.not_to raise_error
    expect { described_class.new(Group::Ortsgruppe.new, :person) }.not_to raise_error

    expect do
      described_class.new(Group::SacCas.new, :person)
    end.to raise_error("must be section/ortsgruppe")
  end

  describe "validations" do
    let(:person) { Fabricate(:person) }
    let(:join_section) { groups(:bluemlisalp) }
    let(:errors) { obj.errors.full_messages }

    subject(:obj) { described_class.new(join_section, person) }

    it "is invalid if person is not an sac member" do
      expect(obj).not_to be_valid
      expect(errors).to eq ["Person muss Sac Mitglied sein"]
    end

    it "is valid with membership in different section" do
      create_role(:matterhorn_mitglieder, "Mitglied")
      expect(obj).to be_valid
    end

    it "is valid with overlapping membership that is marked for destruction" do
      conflicting_role = create_role(:matterhorn_mitglieder, "Mitglied")
      new_role = Fabricate.build(Group::SektionsMitglieder::Mitglied.sti_name,
        group: join_section, person: person)
      person.reload

      allow(obj).to(receive(:prepare_roles)) { [conflicting_role, new_role] }
      expect(obj).not_to be_valid

      conflicting_role.mark_for_destruction
      expect(obj).to be_valid
    end

    it "is invalid and contains all validation and role validation errors" do
      allow(obj).to receive(:prepare_roles) do |person|
        # invalid role without group
        Fabricate.build(Group::SektionsMitglieder::Mitglied.sti_name,
          person: person)
      end

      expect(obj).not_to be_valid
      expect(errors).to eq ["Person muss Sac Mitglied sein",
        "#{person}: Group muss ausgefüllt werden"]
    end

    describe "existing membership in tree" do
      describe "join section" do
        it "is invalid if person is join section member" do
          create_role(:bluemlisalp_mitglieder, "Mitglied")
          expect(obj).not_to be_valid
          expect(errors).to eq [
            "Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch"
          ]
        end

        it "is invalid if person has requested membership via section" do
          create_role(:bluemlisalp_neuanmeldungen_sektion, "Neuanmeldung")
          expect(obj).not_to be_valid
          expect(errors).to eq [
            "Person muss Sac Mitglied sein",
            "Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch"
          ]
        end

        it "is invalid if person has requested membership via nv" do
          create_role(:bluemlisalp_neuanmeldungen_nv, "Neuanmeldung")
          expect(obj).not_to be_valid
          expect(errors).to eq [
            "Person muss Sac Mitglied sein",
            "Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch"
          ]
        end
      end

      describe "ortsgruppe" do
        it "is valid if person is ortsgruppen member" do
          create_role(:bluemlisalp_ortsgruppe_ausserberg_mitglieder, "Mitglied")
          expect(obj).to be_valid
        end

        it "is invalid if person has requested membership" do
          create_role(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv, "Neuanmeldung")
          expect(obj).not_to be_valid
          expect(errors).to eq [
            "Person muss Sac Mitglied sein"
          ]
        end
      end
    end

    context "family main person" do
      it "is invalid when obj validates and person is not main family person" do
        expect(obj).to receive(:validate_family_main_person?).and_return(true)
        create_role(:bluemlisalp_mitglieder, "Mitglied")
        expect(obj).not_to be_valid
        expect(errors).to eq [
          "Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch",
          "Person muss Hauptperson der Familie sein"
        ]
      end

      it "is valid when obj validates and person is not main family person" do
        expect(obj).to receive(:validate_family_main_person?).and_return(true)
        person.update!(sac_family_main_person: true)
        create_role(:bluemlisalp_mitglieder, "Mitglied").tap do |r|
          Role.where(id: r.id).update_all(beitragskategorie: :family)
        end
        expect(obj).not_to be_valid
        expect(errors).to eq [
          "Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch"
        ]
      end
    end
  end

  describe "saving" do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:matterhorn) }
    let(:errors) { obj.errors.full_messages }

    subject(:obj) { described_class.new(group, person) }

    context "invalid" do
      it "save returns false and populates errors" do
        expect(obj.save).to eq false
        expect(obj.errors.full_messages).to eq ["Person muss Sac Mitglied sein"]
      end

      it "save! raises" do
        expect { obj.save! }.to raise_error(/cannot save invalid model/)
      end
    end

    context "single person" do
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }
      let(:matterhorn_funktionaere) { groups(:matterhorn_funktionaere) }
      let!(:bluemlisalp_mitglied) { create_role(:bluemlisalp_mitglieder, "Mitglied") }

      it "creates single role for person" do
        allow(obj).to receive(:prepare_roles) do |person|
          Fabricate.build(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
            person: person, group: matterhorn_mitglieder)
        end
        expect do
          expect(obj.save).to eq true
        end.to change { person.reload.roles.count }.by(1)
      end

      it "might process multiple roles for single person" do
        bluemlisalp_mitglied.attributes = {
          created_at: 1.year.ago,
          deleted_at: Time.zone.yesterday.end_of_day,
          delete_on: nil
        }
        allow(obj).to receive(:prepare_roles) do |person|
          [bluemlisalp_mitglied,
            Fabricate.build(Group::SektionsMitglieder::Mitglied.sti_name,
              group: matterhorn_mitglieder,
              person: person)]
        end
        expect(obj.save).to eq true
        sac_membership = People::SacMembership.new(person)
        person.reload
        expect(sac_membership.active_in?(groups(:matterhorn))).to eq(true)
        expect(sac_membership.active_in?(groups(:bluemlisalp))).to eq(false)
      end

      it "destroys roles marked for destruction" do
        conflicting_role = bluemlisalp_mitglied
        conflicting_role.mark_for_destruction
        new_role = Fabricate.build(Group::SektionsMitglieder::Mitglied.sti_name,
          group: groups(:matterhorn_mitglieder), person: person)

        allow(obj).to(receive(:prepare_roles)) { [conflicting_role, new_role] }

        expect(obj.save).to eq true

        expect { conflicting_role.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(new_role.reload).to be_present
      end
    end

    context "family" do
      let(:other) { Fabricate(:person) }
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }

      def create_sac_family(person, *others)
        person.update!(sac_family_main_person: true)
        household = Household.new(person)
        others.each { |member| household.add(member) }
        household.save!
        person.reload
        others.each(&:reload)
      end

      before do
        person.update!(sac_family_main_person: true)
        person_role = create_role(:bluemlisalp_mitglieder, "Mitglied")
        other_role = create_role(:bluemlisalp_mitglieder, "Mitglied", owner: other.reload)
        create_sac_family(person, other)
        Role.where(id: [person_role.id, other_role.id]).update_all(beitragskategorie: :family)
      end

      it "creates roles for each member" do
        allow(obj).to receive(:prepare_roles) do |person|
          Fabricate.build(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
            person: person, group: matterhorn_mitglieder)
        end

        expect do
          expect(obj.save!).to eq true
        end.to change { Role.count }.by(2)
      end
    end
  end
end
