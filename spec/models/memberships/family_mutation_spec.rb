# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::FamilyMutation do
  # move time to where the roles from the fixtures are valid (mid of 2015)
  before { travel_to Time.zone.local(2015, 8, 1, 12) }

  let(:reference_person) { people(:familienmitglied) }
  let(:household_key) { reference_person.household_key }
  let!(:person) { Fabricate(:person, household_key:, birthday: 35.years.ago) }
  subject(:mutation) { described_class.new(person) }

  let(:stammsektion_class) { Group::SektionsMitglieder::Mitglied }
  let(:zusatzsektion_class) { Group::SektionsMitglieder::MitgliedZusatzsektion }
  let(:neuanmeldung_zusatzsektion_class) { Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion }

  def stammsektion_role = person.sac_membership.stammsektion_role

  def zusatzsektion_roles = person.sac_membership.zusatzsektion_roles

  def neuanmeldung_zusatzsektion_roles = person.sac_membership.neuanmeldung_zusatzsektion_roles

  def create_role!(role_class, group, beitragskategorie: "family", **opts)
    Fabricate(
      role_class.sti_name,
      group:,
      beitragskategorie:,
      **opts.reverse_merge(
        person:,
        start_on: Time.current.beginning_of_year,
        end_on: Date.current.end_of_year
      )
    )
  end

  describe "#change_zusatzsektion_to_family" do
    let(:household_key) { SecureRandom.uuid }

    let(:household) { person.household }

    before do
      household.set_family_main_person!
      create_role!(stammsektion_class, groups(:bluemlisalp_mitglieder))
      create_role!(zusatzsektion_class, groups(:matterhorn_mitglieder), beitragskategorie: :adult)
    end

    it "raises when person is not family main person" do
      other = Fabricate(:person, birthday: 13.years.ago)
      household.add(other).save!
      household.set_family_main_person!(other)

      zusatzsektion_role = zusatzsektion_roles.first

      expect { mutation.change_zusatzsektion_to_family!(zusatzsektion_role) }
        .to raise_error("not able to change zusatzsektion to family")
    end

    it "raises if role has ended" do
      zusatzsektion_role = zusatzsektion_roles.first
      zusatzsektion_role.update!(end_on: Time.zone.yesterday)

      expect { mutation.change_zusatzsektion_to_family!(zusatzsektion_role) }
        .to raise_error("not able to change zusatzsektion to family")
    end

    it "raises if role is terminated" do
      zusatzsektion_role = zusatzsektion_roles.first

      Roles::Termination.new(role: zusatzsektion_role, terminate_on: Time.zone.yesterday, validate_terminate_on: false).call

      expect { mutation.change_zusatzsektion_to_family!(zusatzsektion_role) }
        .to raise_error("not able to change zusatzsektion to family")
    end

    it "raises if role is already family" do
      zusatzsektion_role = zusatzsektion_roles.first

      expect { mutation.change_zusatzsektion_to_family!(zusatzsektion_role) }
        .to change { zusatzsektion_roles.first.reload.beitragskategorie }.from("adult").to("family")

      expect { mutation.change_zusatzsektion_to_family!(zusatzsektion_role) }
        .to raise_error("not able to change zusatzsektion to family")
    end

    it "raises if person is not in a family membership" do
      stammsektion_role.delete
      create_role!(stammsektion_class, groups(:bluemlisalp_mitglieder), beitragskategorie: :adult)
      zusatzsektion_role = zusatzsektion_roles.first

      expect { mutation.change_zusatzsektion_to_family!(zusatzsektion_role) }
        .to raise_error("not able to change zusatzsektion to family")
    end

    it "replaces adult zusatzsektion role" do
      zusatzsektion_role = zusatzsektion_roles.first

      expect { mutation.change_zusatzsektion_to_family!(zusatzsektion_role) }
        .to change { zusatzsektion_roles.first.reload.beitragskategorie }.from("adult").to("family")
    end

    it "adds zusatzsektion role for all family members" do
      other = Fabricate(:person, birthday: 13.years.ago)
      other2 = Fabricate(:person, birthday: 13.years.ago)
      household.add(other)
      household.add(other2)
      household.save!
      zusatzsektion_role = zusatzsektion_roles.first

      expect { mutation.change_zusatzsektion_to_family!(zusatzsektion_role) }
        .to change { zusatzsektion_roles.first.reload.beitragskategorie }.from("adult").to("family")

      [other, other2].each do |family_member|
        created_role = family_member.roles.last

        expect(created_role.type).to eq(zusatzsektion_class.sti_name)
        expect(created_role.beitragskategorie).to eq("family")
        expect(created_role.start_on).to eq(zusatzsektion_roles.first.reload.start_on)
        expect(created_role.end_on).to eq(zusatzsektion_roles.first.reload.end_on)
      end
    end

    it "replaces neuanmeldungs role for family member" do
      other = Fabricate(:person, birthday: 13.years.ago)
      other2 = Fabricate(:person, birthday: 13.years.ago)
      household.add(other)
      household.add(other2)
      household.save!
      neuanmeldung_role = create_role!(neuanmeldung_zusatzsektion_class, groups(:matterhorn_neuanmeldungen_nv), beitragskategorie: :adult, person: other, start_on: other.roles.first.start_on)

      zusatzsektion_role = zusatzsektion_roles.first
      expect { mutation.change_zusatzsektion_to_family!(zusatzsektion_role) }
        .to change { zusatzsektion_roles.first.reload.beitragskategorie }.from("adult").to("family")

      expect(Role.where(id: neuanmeldung_role.id)).to eq([])
    end
  end

  describe "#join!" do
    context "as a member" do
      before { create_role!(stammsektion_class, groups(:bluemlisalp_mitglieder)) }

      it "ends existing stammsektion role per end of yesterday" do
        original_role = stammsektion_role

        expect { mutation.join!(reference_person) }
          .to change { original_role.reload.end_on }.to(Date.yesterday)
      end

      it "ends existing neuanmeldung stammsektion role per end of yesterday" do
        person.roles.destroy_all
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.name.to_sym, group: groups(:bluemlisalp_neuanmeldungen_nv),
          person:,
          start_on: 10.days.ago,
          end_on: 10.days.from_now)

        original_role = person.roles.first

        expect { mutation.join!(reference_person) }
          .to change { original_role.reload.end_on }.to(Date.yesterday)
      end

      it "destroys exsitisting stammsektion role when starting today" do
        stammsektion_role.update!(start_on: Time.zone.today, end_on: 5.days.from_now)
        original_role = stammsektion_role

        expect { mutation.join!(reference_person) }
          .to change { Role.count }.by(1)
        expect { original_role.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "creates new family stammsektion role per today" do
        # reference_person has stammsektion in bluemlisalp_mitglieder
        expect { mutation.join!(reference_person) }
          .to(change { stammsektion_role.id })

        new_role = stammsektion_role
        expect(new_role.group_id).to eq groups(:bluemlisalp_mitglieder).id
        expect(new_role.start_on).to eq Date.current
        expect(new_role.beitragskategorie).to eq "family"
      end

      it "ends existing conflicting zusatzsektion roles per yesterday" do
        conflicting_role = create_role!(zusatzsektion_class, groups(:matterhorn_mitglieder))

        expect { mutation.join!(reference_person) }
          .to change { conflicting_role.reload.end_on }.to(Date.current.yesterday)
      end

      it "does not touch non-conflicting zusatzsektion roles" do
        non_conflicting_role = create_role!(zusatzsektion_class,
          groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder))

        expect { mutation.join!(reference_person) }
          .to not_change { non_conflicting_role.reload.end_on }
          .and(not_change { non_conflicting_role.beitragskategorie })
      end

      it "creates missing family zusatzsektion roles per today" do
        # reference_person has zusatzsektion in matterhorn_mitglieder
        expect { mutation.join!(reference_person) }
          .to change { zusatzsektion_roles.count }.from(0).to(1)

        new_role = zusatzsektion_roles.first
        expect(new_role.group_id).to eq groups(:matterhorn_mitglieder).id
        expect(new_role.start_on).to eq Date.current
        expect(new_role.beitragskategorie).to eq "family"
      end

      it "ignores einzel zusatzsektion roles of reference person" do
        create_role!(zusatzsektion_class,
          groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          person: reference_person,
          beitragskategorie: "adult")

        expect { mutation.join!(reference_person) }.
          # expected to create only one zusatzsektion role for matterhorn_mitglieder but not
          # for bluemlisalp_ortsgruppe_ausserberg_mitglieder
          to change { zusatzsektion_roles.count }.from(0).to(1)

        expect(zusatzsektion_roles.map(&:group_id)).to eq [groups(:matterhorn_mitglieder).id]
      end

      it "does not raise if blueprint_role start_on is nil" do
        reference_person.sac_membership.stammsektion_role.update_columns(start_on: nil)
        expect { mutation.join!(reference_person) }
          .not_to raise_error
      end

      it "raises if person has terminated membership" do
        Role.where(id: stammsektion_role).update_all(terminated: true)
        expect { mutation.join!(reference_person) }
          .to raise_error("not allowed with terminated sac membership")
      end

      it "raises if reference person has terminated membership" do
        Role.where(id: reference_person.sac_membership.stammsektion_role).update_all(terminated: true)
        expect { mutation.join!(reference_person) }
          .to raise_error("not allowed with terminated sac membership")
      end

      it "destroys new family stammsektion role when joining and leaving the family in the same day" do
        expect { mutation.join!(reference_person) }
          .to change { stammsektion_role.id }

        stammsektion_role_in_family = stammsektion_role

        expect { mutation.leave! }
          .to change { stammsektion_role.id }
        expect { stammsektion_role_in_family.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "as a non-member person" do
      it "creates new family stammsektion role" do
        expect { mutation.join!(reference_person) }
          .to change { stammsektion_role&.group_id }.to(groups(:bluemlisalp_mitglieder).id)

        expect(stammsektion_role.beitragskategorie).to eq "family"
      end

      it "creates new family zusatzsektion roles" do
        expect { mutation.join!(reference_person) }
          .to change { zusatzsektion_roles.count }.from(0).to(1)

        new_role = zusatzsektion_roles.first
        expect(new_role.group_id).to eq groups(:matterhorn_mitglieder).id
        expect(new_role.beitragskategorie).to eq "family"
      end

      it "raises if reference person has terminated membership" do
        Role.where(id: reference_person.sac_membership.stammsektion_role).update_all(terminated: true)
        expect { mutation.join!(reference_person) }
          .to raise_error("not allowed with terminated sac membership")
      end
    end
  end

  describe "#leave!" do
    let(:person) { people(:familienmitglied2) }

    it "ends existing family stammsektion role per end of yesterday" do
      original_role = stammsektion_role

      expect { mutation.leave! }
        .to change { original_role.reload.end_on }.to(Date.current.yesterday)
    end

    it "ends exististing family stammsektion role when start on is today" do
      stammsektion_role.update!(start_on: Time.zone.today, end_on: 5.days.from_now)
      original_role = stammsektion_role

      expect { mutation.join!(reference_person) }
        .to change { stammsektion_role.id }
      expect { original_role.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "creates new non-family stammsektion role per today" do
      expect { mutation.leave! }
        .to(change { stammsektion_role.id })

      new_role = stammsektion_role
      expect(new_role.group_id).to eq groups(:bluemlisalp_mitglieder).id
      expect(new_role.start_on).to eq Date.current
      expect(new_role.beitragskategorie).to eq "youth"
    end

    it "terminates family zusatzsektion roles per end of yesterday" do
      family_zusatzsektion_role = zusatzsektion_roles.first
      expect(family_zusatzsektion_role.beitragskategorie).to eq "family"

      expect { mutation.leave! }
        .to change {
          family_zusatzsektion_role.reload.end_on
        }.to(Date.current.yesterday)
    end

    it "creates new non-family zusatzsektion roles for famliy zusatzsektion roles per today" do
      family_zusatzsektion_role = zusatzsektion_roles.first
      expect(family_zusatzsektion_role.beitragskategorie).to eq "family"

      expect { mutation.leave! }
        .not_to change { zusatzsektion_roles.count }.from(1)

      new_role = zusatzsektion_roles.first
      expect(new_role.group_id).to eq groups(:matterhorn_mitglieder).id
      expect(new_role.start_on).to eq Date.current
      expect(new_role.beitragskategorie).to eq "youth"
    end

    it "terminates family neuanmeldung zusatzsektion roles per end of yesterday" do
      create_role!(neuanmeldung_zusatzsektion_class, groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv))
      neuanmeldung_zusatzsektion_role = neuanmeldung_zusatzsektion_roles.first
      expect(neuanmeldung_zusatzsektion_role.beitragskategorie).to eq "family"

      expect { mutation.leave! }
        .to change { neuanmeldung_zusatzsektion_role.reload.end_on }.to(Date.current.yesterday)
    end

    it "does not touch non-family zusatzsektion roles" do
      non_family_zusatzsektion_role = zusatzsektion_roles.first
      Role.where(id: non_family_zusatzsektion_role.id).update_all(beitragskategorie: "youth")

      expect { mutation.leave! }
        .to not_change { non_family_zusatzsektion_role.reload.end_on }
        .and(not_change { non_family_zusatzsektion_role.reload.beitragskategorie })
    end

    it "does not crash if the person has no stammsektion" do
      Role.where(person_id: roles(:familienmitglied).id).delete_all
      mutation = described_class.new(people(:familienmitglied))
      expect { mutation.leave! }.not_to raise_error
    end

    it "destroys new stammsektion role when leaving and joining new family in the same day" do
      expect { mutation.leave! }
        .to change { stammsektion_role.id }

      stammsektion_role_after_family = stammsektion_role

      expect { mutation.join!(reference_person) }
        .to change { stammsektion_role.id }
      expect { stammsektion_role_after_family.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
