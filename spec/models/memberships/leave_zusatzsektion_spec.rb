# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::LeaveZusatzsektion do
  def create_role(key, role, owner: person, **attrs)
    group = key.is_a?(Group) ? key : groups(key)
    role_type = group.class.const_get(role)
    attrs.reverse_merge!(
      group:,
      person: owner,
      start_on: 1.year.ago,
      end_on: Date.current.end_of_year
    )
    Fabricate(role_type.sti_name, **attrs)
  end

  before { travel_to(now) }

  let(:terminate_on) { now.yesterday.to_date }
  let(:now) { Time.zone.local(2024, 6, 19, 15, 33) }
  let(:termination_reason) { termination_reasons(:moved) }

  describe "initialization exceptions" do
    it "raises if role type is invalid" do
      expect do
        described_class.new(Role.new, :termination_date,
          termination_reason_id: termination_reason.id)
      end.to raise_error("wrong type")
    end

    it "raises if role is family and person is not main person" do
      expect do
        role = Group::SektionsMitglieder::MitgliedZusatzsektion.new(
          beitragskategorie: "family",
          person: Person.new
        )
        described_class.new(role, :termination_date, termination_reason_id: termination_reason.id)
      end.to raise_error("not main family person")
    end
  end

  subject(:leave) {
    described_class.new(role, terminate_on, termination_reason_id: termination_reason.id)
  }

  describe "validations" do
    let(:person) { Fabricate(:person) }
    let!(:mitglied) { create_role(:matterhorn_mitglieder, "Mitglied", owner: person) }
    let!(:role) { create_role(:bluemlisalp_mitglieder, "MitgliedZusatzsektion", owner: person) }

    it "is valid" do
      expect(leave).to be_valid
    end

    context "without termination_reason_id" do
      subject(:leave) { described_class.new(role, terminate_on) }

      it "is invalid" do
        expect(leave).not_to be_valid
        expect(leave.errors[:termination_reason_id]).to include("muss ausgefüllt werden")
      end
    end

    describe "validates date" do
      def leave_on(date) = described_class.new(role, date,
        termination_reason_id: termination_reason.id)

      it "is valid on yesterday and at the end of current year" do
        expect(leave_on(now.yesterday.to_date)).to be_valid
        expect(leave_on(now.end_of_year.to_date)).to be_valid
        expect(leave_on(now)).not_to be_valid
        expect(leave_on(now.next_year.beginning_of_year)).not_to be_valid
        expect(leave_on(now.next_year.beginning_of_year.to_date + 1.day)).not_to be_valid
      end
    end
  end

  describe "saving" do
    let(:person) { Fabricate(:person) }

    context "single person" do
      let!(:mitglied) { create_role(:matterhorn_mitglieder, "Mitglied", owner: person) }
      let!(:role) { create_role(:bluemlisalp_mitglieder, "MitgliedZusatzsektion", owner: person) }

      it "deletes existing role" do
        expect do
          expect(leave.save).to eq true
        end.to change { person.roles.count }.by(-1)
        expect { Role.find(role.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "deletes existing role when already schedule for deletion" do
        Roles::Termination.new(role: role, terminate_on: 3.days.from_now.to_date).call
        expect do
          expect(leave.save).to eq true
        end.to change { person.roles.count }.by(-1)
        expect { Role.find(role.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context "with terminate_on at the end of year" do
        let(:terminate_on) { now.end_of_year.to_date }

        it "schedules role for deletion" do
          expect do
            expect(leave.save).to eq true
          end.not_to(change { person.roles.count })
          expect(role.reload).to be_terminated
          expect(role.end_on).to eq Date.new(2024, 12, 31)
        end

        it "does not reset delete_on to a later date" do
          Roles::Termination.new(role: role, terminate_on: 3.days.from_now.to_date).call
          expect do
            expect(leave.save).to eq true
          end.not_to(change { person.roles.count })
          expect(role.reload).to be_terminated
          expect(role.end_on).to eq 3.days.from_now.to_date
        end
      end
    end

    context "family person" do
      let(:other) { Fabricate(:person) }
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }

      subject(:leave) {
        described_class.new(@matterhorn_zusatz, terminate_on,
          termination_reason_id: termination_reason.id)
      }

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
        @bluemlisalp_mitglied = create_role(:bluemlisalp_mitglieder, "Mitglied")
        @bluemlisalp_mitglied_other = create_role(:bluemlisalp_mitglieder, "Mitglied",
          owner: other.reload)
        create_sac_family(person, other)
        Role.where(id: [@bluemlisalp_mitglied.id,
          @bluemlisalp_mitglied_other.id]).update_all(beitragskategorie: :family)

        @matterhorn_zusatz = create_role(
          :matterhorn_mitglieder, "MitgliedZusatzsektion",
          owner: person
        )
        @matterhorn_zusatz_other = create_role(
          :matterhorn_mitglieder, "MitgliedZusatzsektion",
          owner: other
        )
      end

      it "ends role per yesterday" do
        expect do
          expect(leave.save).to eq true
        end.to change { Role.count }.by(-2)
          .and change { @matterhorn_zusatz.reload.end_on }.to(now.to_date.yesterday)
          .and change { @matterhorn_zusatz_other.reload.end_on }.to(now.to_date.yesterday)
      end

      context "with terminate_on at the end of year" do
        let(:terminate_on) { now.end_of_year.to_date }

        it "schedules role for deletion" do
          expect do
            expect(leave.save).to eq true
          end.not_to(change { person.roles.count })
          expect(@matterhorn_zusatz.reload).to be_terminated
          expect(@matterhorn_zusatz_other.end_on).to eq Date.new(2024, 12, 31)
        end
      end
    end
  end
end
