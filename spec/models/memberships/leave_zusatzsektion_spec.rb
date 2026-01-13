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
        described_class.new(Role.new, terminate_on:,
          termination_reason_id: termination_reason.id)
      end.to raise_error("wrong type")
    end

    it "raises if role is family and person is not main person" do
      expect do
        role = Group::SektionsMitglieder::MitgliedZusatzsektion.new(
          beitragskategorie: "family",
          person: Person.new
        )
        described_class.new(role, terminate_on:, termination_reason_id: termination_reason.id)
      end.to raise_error("not main family person")
    end
  end

  subject(:leave) {
    described_class.new(role, terminate_on: terminate_on, termination_reason_id: termination_reason.id)
  }

  describe "validations" do
    let(:person) { Fabricate(:person) }
    let!(:mitglied) { create_role(:matterhorn_mitglieder, "Mitglied", owner: person) }
    let!(:role) { create_role(:bluemlisalp_mitglieder, "MitgliedZusatzsektion", owner: person) }

    it "is valid" do
      expect(leave).to be_valid
    end

    context "without termination_reason_id" do
      subject(:leave) { described_class.new(role, terminate_on: terminate_on) }

      it "is invalid" do
        expect(leave).not_to be_valid
        expect(leave.errors[:termination_reason_id]).to include("muss ausgefüllt werden")
      end
    end

    describe "validates date" do
      def leave_on(date) = described_class.new(role, terminate_on: date,
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

      it "deletes existing role when it has no start_on" do
        role = create_role(:bluemlisalp_touren_und_kurse, "TourenleiterOhneQualifikation", owner: person)
        role.update_columns(start_on: nil)
        expect do
          expect(leave.save).to eq true
        end.to change { person.roles.count }.by(-2)
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
      subject(:leave) {
        described_class.new(role, terminate_on:, termination_reason_id: termination_reason.id)
      }

      let!(:familienmitglied_zweitsektion) { roles(:familienmitglied_zweitsektion) }
      let!(:familienmitglied2_zweitsektion) { roles(:familienmitglied2_zweitsektion) }
      let!(:familienmitglied_kind_zweitsektion) { roles(:familienmitglied_kind_zweitsektion) }

      context "main family person" do
        let(:role) { familienmitglied_zweitsektion }

        it "ends role per yesterday" do
          expect do
            expect(leave.save).to eq true
          end.to change { Role.count }.by(-3)
            .and change { role.reload.end_on }.to(now.to_date.yesterday)
            .and change { familienmitglied2_zweitsektion.reload.end_on }.to(now.to_date.yesterday)
            .and change { familienmitglied_kind_zweitsektion.reload.end_on }.to(now.to_date.yesterday)
        end

        context "with terminate_on at the end of year" do
          let(:terminate_on) { now.end_of_year.to_date }

          it "marks role as terminated but does not change end_on" do
            expect do
              expect(leave.save).to eq true
            end.not_to(change { person.roles.count })
            [
              familienmitglied_zweitsektion,
              familienmitglied2_zweitsektion,
              familienmitglied_kind_zweitsektion
            ].each do |role|
              expect(role.reload).to be_terminated
              expect(role.reload.end_on).to eq Date.new(2024, 12, 31)
            end
          end
        end
      end

      context "non main family person" do
        let(:role) { familienmitglied2_zweitsektion }

        it "raises error" do
          expect { leave.save }.to raise_error(RuntimeError, "not main family person")
        end

        it "might leave if beitragskategorie is not family" do
          Role.where(id: familienmitglied2_zweitsektion.id).update_all(beitragskategorie: :adult)
          expect do
            expect(leave.save).to eq true
          end.to change { Role.count }.by(-1)
            .and change { role.reload.end_on }.to(now.to_date.yesterday)
            .and not_change { familienmitglied_zweitsektion.reload.end_on }
            .and not_change { familienmitglied_kind_zweitsektion.reload.end_on }
        end
      end
    end
  end
end
