# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::FamilyMutation do
  let(:reference_person) { people(:familienmitglied) }
  let(:household_key) { reference_person.household_key }
  let!(:person) { Fabricate(:person, household_key:, birthday: 35.years.ago) }
  subject(:mutation) { described_class.new(person) }

  # move time to where the roles from the fixtures are valid (mid of 2015)
  before { travel_to Time.zone.local(2015, 8, 1, 12) }

  let(:stammsektion_class) { Group::SektionsMitglieder::Mitglied }
  let(:zusatzsektion_class) { Group::SektionsMitglieder::MitgliedZusatzsektion }

  def stammsektion_role = person.sac_membership.stammsektion_role

  def zusatzsektion_roles = person.sac_membership.zusatzsektion_roles

  def create_role!(role_class, group, beitragskategorie: "family", **opts)
    Fabricate(
      role_class.sti_name,
      group:,
      beitragskategorie:,
      created_at: Time.current.beginning_of_year,
      delete_on: Date.current.end_of_year,
      **opts.reverse_merge(person:)
    )
  end

  describe "#join!" do
    context "as a member" do
      before { create_role!(stammsektion_class, groups(:bluemlisalp_mitglieder)) }

      it "terminates existing stammsektion role per end of yesterday" do
        original_role = stammsektion_role

        expect { mutation.join!(reference_person) }
          .to change { original_role.reload.deleted_at }.to(Time.zone.yesterday.end_of_day.floor)
          .and change { original_role.delete_on }.to(nil)
      end

      it "creates new family stammsektion role per beginning of today" do
        # reference_person has stammsektion in bluemlisalp_mitglieder
        expect { mutation.join!(reference_person) }
          .to(change { stammsektion_role.id })

        new_role = stammsektion_role
        expect(new_role.group_id).to eq groups(:bluemlisalp_mitglieder).id
        expect(new_role.created_at).to eq Time.current.beginning_of_day
        expect(new_role.beitragskategorie).to eq "family"
      end

      it "terminates existing conflicting zusatzsektion roles per end of yesterday" do
        conflicting_role = create_role!(zusatzsektion_class, groups(:matterhorn_mitglieder))

        expect { mutation.join!(reference_person) }
          .to change { conflicting_role.reload.deleted_at }.to(Time.zone.yesterday.end_of_day.floor)
          .and change { conflicting_role.delete_on }.to(nil)
      end

      it "does not touch non-conflicting zusatzsektion roles" do
        non_conflicting_role = create_role!(zusatzsektion_class,
          groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder))

        expect { mutation.join!(reference_person) }
          .to not_change { non_conflicting_role.reload.deleted_at }
          .and(not_change { non_conflicting_role.beitragskategorie })
      end

      it "creates missing family zusatzsektion roles per beginning of today" do
        # reference_person has zusatzsektion in matterhorn_mitglieder
        expect { mutation.join!(reference_person) }
          .to change { zusatzsektion_roles.count }.from(0).to(1)

        new_role = zusatzsektion_roles.first
        expect(new_role.group_id).to eq groups(:matterhorn_mitglieder).id
        expect(new_role.created_at).to eq Time.current.beginning_of_day
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

      it "handles future roles" do
        reference_future_role = FutureRole.create!(
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          person: reference_person,
          beitragskategorie: "family",
          convert_on: Date.current.next_year.beginning_of_year,
          convert_to: stammsektion_class.sti_name,
          created_at: 1.day.ago
        )

        expect { mutation.join!(reference_person) }
          .to change { person.sac_membership.future_stammsektion_roles.count }.from(0).to(1)

        new_future_role = person.sac_membership.future_stammsektion_roles.first
        expect(new_future_role.group_id).to eq groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder).id
        expect(new_future_role.created_at).to eq Time.current.beginning_of_day
        expect(new_future_role.beitragskategorie).to eq "family"
        expect(new_future_role.convert_on).to eq reference_future_role.convert_on
        expect(new_future_role.convert_to).to eq reference_future_role.convert_to
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

    it "terminates existing family stammsektion role per end of yesterday" do
      original_role = stammsektion_role

      expect { mutation.leave! }
        .to change { original_role.reload.deleted_at }.to(Time.zone.yesterday.end_of_day.floor)
        .and change { original_role.delete_on }.to(nil)
    end

    it "creates new non-family stammsektion role per beginning of today" do
      expect { mutation.leave! }
        .to(change { stammsektion_role.id })

      new_role = stammsektion_role
      expect(new_role.group_id).to eq groups(:bluemlisalp_mitglieder).id
      expect(new_role.created_at).to eq Time.current.beginning_of_day
      expect(new_role.beitragskategorie).to eq "youth"
    end

    it "terminates family zusatzsektion roles per end of yesterday" do
      family_zusatzsektion_role = zusatzsektion_roles.first
      expect(family_zusatzsektion_role.beitragskategorie).to eq "family"

      expect { mutation.leave! }
        .to change {
          family_zusatzsektion_role.reload.deleted_at
        }.to(Time.zone.yesterday.end_of_day.floor)
        .and change { family_zusatzsektion_role.delete_on }.to(nil)
    end

    it "creates new non-family zusatzsektion roles for famliy zusatzsektion roles per beginning of today" do
      family_zusatzsektion_role = zusatzsektion_roles.first
      expect(family_zusatzsektion_role.beitragskategorie).to eq "family"

      expect { mutation.leave! }
        .not_to change { zusatzsektion_roles.count }.from(1)

      new_role = zusatzsektion_roles.first
      expect(new_role.group_id).to eq groups(:matterhorn_mitglieder).id
      expect(new_role.created_at).to eq Time.current.beginning_of_day
      expect(new_role.beitragskategorie).to eq "youth"
    end

    it "does not touch non-family zusatzsektion roles" do
      non_family_zusatzsektion_role = zusatzsektion_roles.first
      Role.where(id: non_family_zusatzsektion_role.id).update_all(beitragskategorie: "youth")

      expect { mutation.leave! }
        .to not_change { non_family_zusatzsektion_role.reload.deleted_at }
        .and(not_change { non_family_zusatzsektion_role.reload.beitragskategorie })
    end

    it "handles future roles" do
      original_future_stammsektion_role = FutureRole.create!(
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
        person:,
        beitragskategorie: "family",
        convert_on: Date.current.next_year.beginning_of_year,
        convert_to: stammsektion_class.sti_name,
        created_at: 1.day.ago
      )

      expect { mutation.leave! }
        .to not_change { person.sac_membership.future_stammsektion_roles.count }.from(1)
        .and(change { person.sac_membership.future_stammsektion_roles.first.id })

      new_future_role = person.sac_membership.future_stammsektion_roles.first
      expect(new_future_role.group_id).to eq original_future_stammsektion_role.group_id
      expect(new_future_role.created_at).to eq Time.current.beginning_of_day
      expect(new_future_role.beitragskategorie).to eq "youth"
      expect(new_future_role.convert_on).to eq original_future_stammsektion_role.convert_on
      expect(new_future_role.convert_to).to eq original_future_stammsektion_role.convert_to
    end
  end
end
