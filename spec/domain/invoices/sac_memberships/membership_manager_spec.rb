# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::SacMemberships::MembershipManager do
  include ActiveJob::TestHelper

  let!(:today) { Time.zone.today }
  let!(:end_of_next_year) { today.next_year.end_of_year }
  let!(:prolongation_date) { Date.new(next_year, 3, 31) }
  let!(:run_on) { Time.current.change(year: next_year, month: 2, day: 15) }
  let(:next_year) { end_of_next_year.year }
  let(:mitglied) { roles(:mitglied) }
  let(:mitglied_zweitsektion) { roles(:mitglied_zweitsektion) }
  let(:familienmitglied) { roles(:familienmitglied) }
  let(:familienmitglied_zweitsektion) { roles(:familienmitglied_zweitsektion) }
  let(:familienmitglied2) { roles(:familienmitglied2) }
  let(:familienmitglied2_zweitsektion) { roles(:familienmitglied2_zweitsektion) }
  let(:familienmitglied_kind) { roles(:familienmitglied_kind) }
  let(:familienmitglied_kind_zweitsektion) { roles(:familienmitglied_kind_zweitsektion) }

  let(:mitglied_person) { people(:mitglied) }
  let(:familienmitglied_person) { people(:familienmitglied) }
  let(:familienmitglied2_person) { people(:familienmitglied2) }
  let(:familienmitglied_kind_person) { people(:familienmitglied_kind) }

  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:matterhorn) { groups(:matterhorn) }
  let(:ehrenmitglieder_group) do
    Group::Ehrenmitglieder.create!(
      name: "Ehrenmitglieder",
      parent: groups(:root)
    )
  end

  def sac_membership = subject.person.sac_membership

  def create_additional_roles(person)
    Fabricate(Group::SektionsMitglieder::Ehrenmitglied.sti_name,
      group: groups(:bluemlisalp_mitglieder),
      person: person,
      start_on: today.beginning_of_year)
    Fabricate(Group::SektionsMitglieder::Beguenstigt.sti_name,
      group: groups(:bluemlisalp_mitglieder),
      person: person,
      start_on: today.beginning_of_year)
    Fabricate(Group::Ehrenmitglieder::Ehrenmitglied.sti_name,
      group: ehrenmitglieder_group,
      person: person,
      start_on: today.beginning_of_year)
  end

  before do
    people = [
      mitglied_person,
      familienmitglied_person,
      familienmitglied2_person,
      familienmitglied_kind_person
    ]

    people.each { |person| create_additional_roles(person) }
    Role.update_all(end_on: prolongation_date)

    travel_to(run_on)

    people.each(&:reload)
  end

  it "creates log entry if running without any actual work todo" do
    manager = described_class.new(Fabricate(:person), bluemlisalp, next_year)
    expect { manager.update_membership_status }.to change { HitobitoLogEntry.count }.by(1)
  end

  context "person has stammsektions role" do
    def updated_roles_count
      role_dates_before = Role.order(:id).map(&:end_on)

      subject.update_membership_status

      role_dates_after = Role.order(:id).map(&:end_on)

      # check how many dates have changed
      role_dates_after.zip(role_dates_before).count { |a, b| a != b } +
        (role_dates_after.size - role_dates_before.size).abs
    end

    context "adult" do
      subject { described_class.new(mitglied_person, bluemlisalp, next_year) }

      it "updates end_on" do
        expect(updated_roles_count).to eq(5)

        expect(mitglied_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
      end

      it "doesn't update end_on when role is terminated" do
        mitglied_zweitsektion.update_column(:terminated, true)
        expect(updated_roles_count).to eq(4)
      end

      it "doesn't update roles when end_on is already in external invoice year" do
        Role.update_all(end_on: end_of_next_year)
        expect(updated_roles_count).to eq(0)
      end

      it "doesn't update roles when end_on is after external invoice year" do
        Role.update_all(end_on: end_of_next_year + 5.years)
        expect(updated_roles_count).to eq(0)
      end

      it "does not raise error when current stammsektion role does not have end_on defined" do
        mitglied.update_column(:end_on, nil)
        expect { subject.update_membership_status }.not_to raise_error
        expect(mitglied_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
      end

      context "running in the previous role period" do
        let!(:run_on) { Time.current.change(year: today.year, month: 12, day: 15) }

        it "updates end_on if running in the previous role period" do
          expect(updated_roles_count).to eq(5)

          expect(mitglied_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
        end
      end
    end

    context "family" do
      subject { described_class.new(familienmitglied_person, bluemlisalp, next_year) }

      it "updates end_on for all family member roles" do
        expect(updated_roles_count).to eq(15)

        expect(familienmitglied_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
        expect(familienmitglied2_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
        expect(familienmitglied_kind_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
      end

      it "only updates zusatzsektions role of family member when beitragskategorie is family" do
        # add role with adult beitragskategorie to family mitglied
        familienmitglied_person.sac_membership.zusatzsektion_roles.delete_all
        familienmitglied_person.reload
        mitglied_zweitsektion.update!(person: familienmitglied_person)

        expect(updated_roles_count).to eq(14)
      end

      it "only updates own roles when no family main person" do
        allow(familienmitglied_person).to receive(:sac_family_main_person?).and_return(false)
        # Non-main person with only family-type roles has no non-family zusatzsektion
        # to extend, so no roles are updated (main person handles family role extension)
        expect(updated_roles_count).to eq(0)
      end

      context "family member with einzel zusatzsektion pays before stammsektion" do
        before do
          # Give familienmitglied2 an individual (adult) zusatzsektion instead of family.
          # Use update_all to bypass attr_readonly on beitragskategorie.
          Group::SektionsMitglieder::MitgliedZusatzsektion
            .where(id: familienmitglied2_zweitsektion.id)
            .update_all(beitragskategorie: "adult")
          familienmitglied2_zweitsektion.reload
        end

        context "non-main family member pays invoice first" do
          subject { described_class.new(familienmitglied2_person, bluemlisalp, next_year) }

          it "caps zusatzsektion (Einzel) at stammsektion end_on, does not extend to end_of_year" do
            subject.update_membership_status
            familienmitglied2_person.reload

            einzel_role = familienmitglied2_person.sac_membership.zusatzsektion_roles.first
            expect(einzel_role.end_on).to eq prolongation_date
            expect(einzel_role.end_on).not_to eq end_of_next_year
          end

          it "does not extend stammsektion (Familie) role" do
            subject.update_membership_status
            familienmitglied2_person.reload

            expect(familienmitglied2_person.sac_membership.stammsektion_role.end_on)
              .to eq prolongation_date
          end

          it "does not extend prolongable roles (capped at stammsektion end_on)" do
            subject.update_membership_status
            familienmitglied2_person.reload

            familienmitglied2_person.sac_membership.membership_prolongable_roles.each do |role|
              expect(role.end_on).to eq prolongation_date
            end
          end
        end

        context "main person pays stammsektion after family member already paid" do
          subject { described_class.new(familienmitglied_person, bluemlisalp, next_year) }

          before do
            # Create paid external invoice for the family member
            Fabricate(:sac_membership_invoice,
              person: familienmitglied2_person,
              link: bluemlisalp,
              year: next_year,
              state: :payed,
              total: 100)

            # Simulate zusatzsektion was capped at stammsektion end_on
            familienmitglied2_zweitsektion.update!(end_on: prolongation_date)
          end

          it "extends family member's zusatzsektion (Einzel) to end_of_year" do
            subject.update_membership_status
            familienmitglied2_person.reload

            einzel_role = familienmitglied2_person.sac_membership.zusatzsektion_roles.first
            expect(einzel_role.end_on).to eq end_of_next_year
          end
        end

        context "multiple family members with einzel, some paid some not" do
          subject { described_class.new(familienmitglied_person, bluemlisalp, next_year) }

          before do
            # familienmitglied2 has paid Einzel (from outer before)
            Fabricate(:sac_membership_invoice,
              person: familienmitglied2_person,
              link: bluemlisalp,
              year: next_year,
              state: :payed,
              total: 100)
            familienmitglied2_zweitsektion.update!(end_on: prolongation_date)

            # familienmitglied_kind has Einzel but no paid invoice
            # Use update_all to bypass attr_readonly on beitragskategorie
            Group::SektionsMitglieder::MitgliedZusatzsektion
              .where(id: familienmitglied_kind_zweitsektion.id)
              .update_all(beitragskategorie: "adult", end_on: prolongation_date)
            familienmitglied_kind_zweitsektion.reload
          end

          it "extends paid family member's zusatzsektion to end_of_year" do
            subject.update_membership_status

            expect(familienmitglied2_person.reload.sac_membership
              .zusatzsektion_roles.first.end_on).to eq end_of_next_year
          end

          it "does not extend unpaid family member's zusatzsektion" do
            subject.update_membership_status

            expect(familienmitglied_kind_person.reload.sac_membership
              .zusatzsektion_roles.first.end_on).to eq prolongation_date
          end
        end

        context "family member pays after stammsektion already renewed" do
          subject { described_class.new(familienmitglied2_person, bluemlisalp, next_year) }

          before do
            # Simulate stammsektion was already renewed
            familienmitglied2.update!(end_on: end_of_next_year)
            familienmitglied2_person.reload
          end

          it "extends zusatzsektion (Einzel) normally to end_of_year" do
            subject.update_membership_status
            familienmitglied2_person.reload

            einzel_role = familienmitglied2_person.sac_membership.zusatzsektion_roles.first
            expect(einzel_role.end_on).to eq end_of_next_year
          end
        end
      end

      context "running in the previous role period (household still exists)" do
        let!(:run_on) { Time.current.change(year: today.year, month: 12, day: 15) }

        it "updates end_on for all family member roles" do
          expect(updated_roles_count).to eq(15)

          expect(familienmitglied_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
          expect(familienmitglied2_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
          expect(familienmitglied_kind_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
        end
      end

      context "with child turned youth" do
        let(:end_of_year) { Date.new(today.year, 12, 31) }

        before do
          familienmitglied_kind_person.update!(birthday: today - 18.years)
          [familienmitglied_kind, familienmitglied_kind_zweitsektion].each do |role|
            role.update!(end_on: end_of_year)
          end
          Group::SektionsMitglieder::Mitglied.create!(
            person: familienmitglied_kind_person,
            group: groups(:bluemlisalp_mitglieder),
            beitragskategorie: "youth",
            start_on: Date.new(next_year, 1, 1),
            end_on: prolongation_date
          )
          Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
            person: familienmitglied_kind_person,
            group: groups(:matterhorn_mitglieder),
            beitragskategorie: "youth",
            start_on: Date.new(next_year, 1, 1),
            end_on: prolongation_date
          )
        end

        context "running in the new role period (child was removed from household)" do
          before do
            Household.new(familienmitglied_kind_person, maintain_sac_family: false)
              .remove(familienmitglied_kind_person).save!
          end

          it "only updates remaining family roles after child turned to youth" do
            expect(updated_roles_count).to eq(10)
            expect(familienmitglied_kind_person.roles.reload.map(&:end_on)).to all(eq(prolongation_date))
            expect(familienmitglied_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
          end

          context "for youth" do
            subject { described_class.new(familienmitglied_kind_person, bluemlisalp, next_year) }

            it "only updates youth roles" do
              expect(updated_roles_count).to eq(5)
              expect(familienmitglied_person.roles.reload.map(&:end_on)).to all(eq(prolongation_date))
              expect(familienmitglied2_person.roles.reload.map(&:end_on)).to all(eq(prolongation_date))
              expect(familienmitglied_kind_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
            end
          end
        end

        context "running in the previous role period (household still exists)" do
          let!(:run_on) { Time.current.change(year: today.year, month: 12, day: 15) }

          it "only updates remaining family roles" do
            expect(updated_roles_count).to eq(10) # active at run date
            expect(familienmitglied_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
            expect(familienmitglied2_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))

            prev_membership = People::SacMembership.new(familienmitglied_kind_person, date: end_of_year)
            expect(prev_membership.stammsektion_role.end_on).to eq(end_of_year)
            expect(prev_membership.zusatzsektion_roles.first.end_on).to eq(end_of_year)

            next_membership = People::SacMembership.new(familienmitglied_kind_person, date: prolongation_date)
            expect(next_membership.stammsektion_role.end_on).to eq(prolongation_date)
            expect(next_membership.membership_prolongable_roles.count).to eq(3)
            (next_membership.zusatzsektion_roles +
              next_membership.membership_prolongable_roles).each do |role|
              expect(role.end_on).to eq(prolongation_date)
            end
          end

          context "for youth" do
            subject { described_class.new(familienmitglied_kind_person, bluemlisalp, next_year) }

            it "only updates youth roles" do
              expect(updated_roles_count).to eq(3) # active at run date
              expect(familienmitglied_person.roles.reload.map(&:end_on)).to all(eq(prolongation_date))
              expect(familienmitglied2_person.roles.reload.map(&:end_on)).to all(eq(prolongation_date))

              prev_membership = People::SacMembership.new(familienmitglied_kind_person, date: end_of_year)
              expect(prev_membership.stammsektion_role.end_on).to eq(end_of_year)
              expect(prev_membership.zusatzsektion_roles.first.end_on).to eq(end_of_year)

              next_membership = People::SacMembership.new(familienmitglied_kind_person, date: prolongation_date)
              expect(next_membership.stammsektion_role.end_on).to eq(end_of_next_year)
              expect(next_membership.membership_prolongable_roles.count).to eq(3)
              (next_membership.zusatzsektion_roles +
               next_membership.membership_prolongable_roles).each do |role|
                expect(role.end_on).to eq(end_of_next_year)
              end
            end
          end
        end
      end
    end
  end

  context "person has expired stammsektions role" do
    let!(:run_on) { Time.current.change(year: next_year, month: 5, day: 10) }

    def check_new_membership_role_dates_and_groups(person) # rubocop:todo Metrics/AbcSize
      expect(sac_membership.active?).to be_truthy
      expect(sac_membership.stammsektion_role.start_on).to eq run_on.to_date
      expect(sac_membership.stammsektion_role.end_on).to eq end_of_next_year
      expect(sac_membership.zusatzsektion_roles.first.start_on).to eq run_on.to_date
      expect(sac_membership.zusatzsektion_roles.first.end_on).to eq end_of_next_year
      expect(sac_membership.membership_prolongable_roles.first.start_on).to eq run_on.to_date
      expect(sac_membership.membership_prolongable_roles.first.end_on).to eq end_of_next_year
      expect(sac_membership.membership_prolongable_roles.second.start_on).to eq run_on.to_date
      expect(sac_membership.membership_prolongable_roles.second.end_on).to eq end_of_next_year
      expect(sac_membership.membership_prolongable_roles.third.start_on).to eq run_on.to_date
      expect(sac_membership.membership_prolongable_roles.third.end_on).to eq end_of_next_year
    end

    context "adult" do
      subject { described_class.new(mitglied_person, bluemlisalp, next_year) }

      it "creates new stammsektion role for person starting today" do
        expect do
          subject.update_membership_status
        end.to change { Role.count }.by(5)

        check_new_membership_role_dates_and_groups(mitglied_person)
      end

      it "does not create any role if stammsektion role is terminated" do
        mitglied.update_column(:terminated, true)
        expect do
          subject.update_membership_status
        end.not_to change { Role.count }
      end

      it "does not create new zusatzsektion role if zusatzsektion is terminated" do
        mitglied_zweitsektion.update_column(:terminated, true)
        expect do
          subject.update_membership_status
        end.to change { Role.count }.by(4)
        expect(mitglied_person.sac_membership.zusatzsektion_roles).to be_empty
      end

      it "does not create new zusatzsektion role when it ended earlier than stammsektion role" do
        mitglied_zweitsektion.update_column(:end_on, 2.years.ago)
        expect do
          subject.update_membership_status
        end.to change { Role.count }.by(4)
        expect(mitglied_person.sac_membership.zusatzsektion_roles).to be_empty
      end

      it "does not create any role if membership roles ended 1 year ago" do
        mitglied.update_column(:end_on, 1.year.ago)
        expect do
          subject.update_membership_status
        end.not_to change { Role.count }
      end
    end

    context "family" do
      subject { described_class.new(familienmitglied_person, bluemlisalp, next_year) }

      it "creates new stammsektion role for person starting today" do
        expect do
          subject.update_membership_status
        end.to change { Role.count }.by(15)

        check_new_membership_role_dates_and_groups(familienmitglied_person)
        check_new_membership_role_dates_and_groups(familienmitglied2_person)
        check_new_membership_role_dates_and_groups(familienmitglied_kind_person)
      end

      it "does not create zusatzsektion roles for family members when only main person is in zusatzsektionen" do  # rubocop:disable Layout/LineLength
        familienmitglied2_zweitsektion.delete
        familienmitglied_kind_zweitsektion.delete
        familienmitglied2_person.reload
        familienmitglied_kind_person.reload
        expect do
          subject.update_membership_status
        end.to change { Role.count }.by(13)
          .and change { familienmitglied2_person.reload.sac_membership.zusatzsektion_roles.count }.by(0)
          .and change { familienmitglied_kind_person.reload.sac_membership.zusatzsektion_roles.count }.by(0)
      end

      it "only creates zusatzsektion role of family member when beitragskategorie is family" do
        # add role with adult beitragskategorie to family mitglied2
        People::SacMembership.new(familienmitglied2_person, date: Date.new(next_year, 1, 1))
          .zusatzsektion_roles
          .delete_all
        familienmitglied2_person.reload
        mitglied_zweitsektion.update!(
          person: familienmitglied2_person,
          end_on: prolongation_date
        )

        expect do
          subject.update_membership_status
        end.to change { Role.count }.by(14)
          .and change { familienmitglied2_person.sac_membership.zusatzsektion_roles.count }.by(0)
      end

      it "preserves individual beitragskategorie for main person's zusatzsektion role" do
        familienmitglied_zweitsektion.really_destroy!
        Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
          person: familienmitglied_person,
          group: groups(:matterhorn_mitglieder),
          beitragskategorie: :adult, # not: family
          start_on: Date.new(next_year, 1, 1),
          end_on: prolongation_date
        )

        expect do
          subject.update_membership_status

          new_role = familienmitglied_person.reload.sac_membership.zusatzsektion_roles.first
          expect(new_role.beitragskategorie).to eq "adult"
        end.to change { Role.count }.by(15)
      end

      it "restores the household" do
        familienmitglied_person.household.destroy
        familienmitglied_person.update_column(:sac_family_main_person, false)

        expect(familienmitglied_person.sac_family_main_person?).to be false
        expect(familienmitglied_person.household_key).to be_nil

        subject.update_membership_status

        familienmitglied_person.reload
        expect(familienmitglied_person.sac_family_main_person?).to be true
        expect(familienmitglied_person.household_key).not_to be_nil

        # Check that all family members are in the same household
        familienmitglied2_person.reload
        familienmitglied_kind_person.reload
        expect(familienmitglied2_person.household_key).to eq(familienmitglied_person.household_key)
        expect(familienmitglied_kind_person.household_key).to eq(familienmitglied_person.household_key)
      end
    end
  end

  context "person has just a neuanmeldung role" do
    context "adult" do
      let(:new_member) do
        person = Fabricate(:person, birthday: Time.zone.today - 19.years, confirmed_at: nil)
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
          person: person,
          beitragskategorie: :adult,
          group: groups(:bluemlisalp_neuanmeldungen_nv))
        person
      end

      subject do
        described_class.new(new_member, groups(:bluemlisalp_neuanmeldungen_nv), next_year)
      end

      it "creates stammsektion role and enqueues SacMembershipsMailer" do
        expect do
          subject.update_membership_status
        end.to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation).once
        expect(new_member.confirmed_at).to be_nil
        expect(new_member.sac_membership.active?).to eq(true)
        expect(new_member.roles.count).to eq(1)
        expect(new_member.sac_membership.stammsektion_role.end_on).to eq(end_of_next_year)
      end

      it "creates ended stammsektion role for year without enqueuing SacMembershipsMailer if year is in the past" do
        subject = described_class.new(new_member, groups(:bluemlisalp_neuanmeldungen_nv), today.year)
        expect do
          subject.update_membership_status
        end.not_to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation).once
        expect(new_member.confirmed_at).to be_nil
        expect(new_member.sac_membership).to be_present
        expect(new_member.sac_membership.active?).to eq(false)
        expect(new_member.sac_membership.stammsektion_role).to be_nil
        expect(new_member.roles.count).to eq(0)
        expect(new_member.roles.ended.count).to eq(1)
        expect(new_member.roles.ended.first.start_on).to eq today.end_of_year
        expect(new_member.roles.ended.first.end_on).to eq today.end_of_year
      end

      it "does not enqueue SacMembershipsMailer if person has no email" do
        new_member.update(email: nil)
        expect do
          subject.update_membership_status
        end.not_to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation)
        expect(new_member.sac_membership.stammsektion_role.end_on).to eq(end_of_next_year)
      end

      describe "member in past year with neuanmeldung" do
        subject do
          described_class.new(new_member, groups(:bluemlisalp_neuanmeldungen_nv), next_year)
        end

        it "creates stammsektion role and enqueues SacMembershipsMailer with membership role from last year" do
          Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
            person: new_member,
            beitragskategorie: :adult,
            group: groups(:bluemlisalp_mitglieder),
            start_on: Date.new(today.year, 1, 1),
            end_on: Date.new(today.year, 3, 31))
          expect do
            subject.update_membership_status
          end.to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation).once
          expect(new_member.confirmed_at).to be_nil
          expect(new_member.sac_membership.active?).to eq(true)
          expect(new_member.roles.count).to eq(1)
          expect(new_member.sac_membership.stammsektion_role.end_on).to eq(end_of_next_year)
        end
      end
    end

    context "family" do
      before do
        Role.delete_all # avoid Group::SektionsMitglieder#destroy_household callback
        familienmitglied_kind_person.destroy

        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
          person: familienmitglied_person,
          beitragskategorie: :family,
          created_at: 1.year.ago,
          group: groups(:bluemlisalp_neuanmeldungen_nv))

        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
          person: familienmitglied2_person,
          beitragskategorie: :family,
          created_at: 1.year.ago,
          group: groups(:bluemlisalp_neuanmeldungen_nv))
      end

      subject { described_class.new(familienmitglied_person, bluemlisalp, next_year) }

      it "creates stammsektion role" do
        subject.update_membership_status

        expect(familienmitglied_person.sac_membership.active?).to eq(true)
        expect(familienmitglied2_person.sac_membership.active?).to eq(true)
        expect(familienmitglied_person.sac_membership.stammsektion_role.beitragskategorie).to eq "family"
        expect(familienmitglied2_person.sac_membership.stammsektion_role.beitragskategorie).to eq "family"
        expect(familienmitglied_person.roles.count).to eq(1)
        expect(familienmitglied2_person.roles.count).to eq(1)
        expect(familienmitglied_person.sac_membership.stammsektion_role.end_on).to eq(end_of_next_year)
        expect(familienmitglied2_person.sac_membership.stammsektion_role.end_on).to eq(end_of_next_year)
      end

      it "doesn't create role for family members when person is not family main person" do
        allow(familienmitglied_person).to receive(:sac_family_main_person?).and_return(false)

        expect(familienmitglied2_person.sac_membership.active?).to eq(false)
      end
    end
  end

  context "person has just a neuanmeldung zusatzsektion_roles role" do
    context "adult" do
      before do
        membership = People::SacMembership.new(mitglied_person)
        membership.stammsektion_role.update(end_on: end_of_next_year + 5.years)
        membership.zusatzsektion_roles.destroy_all
        membership.membership_prolongable_roles.destroy_all
      end

      let!(:neuanmeldung) do
        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: mitglied_person,
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))
      end

      subject { described_class.new(mitglied_person, matterhorn, next_year) }

      it "creates zusatzsektions role and enqueues SacMembershipsMailer" do
        expect do
          subject.update_membership_status
        end.to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation).once

        expect(mitglied_person.roles.count).to eq(2)
        expect(mitglied_person.sac_membership.zusatzsektion_roles.first.end_on).to eq(end_of_next_year)
      end

      it "does not enqueue SacMembershipsMailer if person has no email" do
        mitglied_person.update(email: nil)
        expect do
          subject.update_membership_status
        end.not_to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation)
        expect(mitglied_person.sac_membership.zusatzsektion_roles.first.end_on).to eq(end_of_next_year)
      end

      it "only creates zusatzsektion for layer in question if two roles exist" do
        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: mitglied_person,
          beitragskategorie: :adult,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv))

        expect do
          subject.update_membership_status
        end.to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation).once

        expect(mitglied_person.roles.count).to eq(3)
        expect(mitglied_person.sac_membership.zusatzsektion_roles.count).to eq 1
        expect(mitglied_person.sac_membership.zusatzsektion_roles.first.group.layer_group).to eq matterhorn
      end

      context "with stammsektions only partially covering year" do
        let!(:run_on) { Date.new(2025, 2, 1) }
        let(:stammsektion_end_on) { Date.new(2025, 5, 1) }

        before do
          neuanmeldung.update!(start_on: Date.new(2025, 2, 1))
          mitglied.update!(end_on: stammsektion_end_on)
        end

        it "creates zusatzsektion role from today to end of stammsektion role" do
          travel_to(Date.new(2025, 3, 1)) do
            subject.update_membership_status

            expect(mitglied_person.sac_membership.zusatzsektion_roles.first.start_on).to eq Date.new(2025, 3, 1)
            expect(mitglied_person.sac_membership.zusatzsektion_roles.first.end_on).to eq stammsektion_end_on
          end
        end

        it "creates role starting and ending on stammsektion end_on if run on after stammsektion expires" do
          travel_to(Date.new(2025, 5, 2)) do
            subject.update_membership_status

            role = mitglied_person.roles.with_inactive.find_by(type: "Group::SektionsMitglieder::MitgliedZusatzsektion")
            expect(role.start_on).to eq stammsektion_end_on
            expect(role.end_on).to eq stammsektion_end_on
          end
        end
      end
    end

    context "family" do
      before do
        familienmitglied_kind_person.destroy

        familienmitglied_person.sac_membership.stammsektion_role.update(end_on: end_of_next_year + 5.years)
        familienmitglied_person.sac_membership.zusatzsektion_roles.destroy_all
        familienmitglied_person.sac_membership.membership_prolongable_roles.destroy_all
        familienmitglied2_person.sac_membership.stammsektion_role.update(end_on: end_of_next_year + 5.years)
        familienmitglied2_person.sac_membership.zusatzsektion_roles.destroy_all
        familienmitglied2_person.sac_membership.membership_prolongable_roles.destroy_all

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: familienmitglied_person,
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: familienmitglied2_person,
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))
      end

      subject {
        described_class.new(familienmitglied_person, groups(:matterhorn_neuanmeldungen_nv),
          next_year)
      }

      it "creates zusatzsektions roles for family members" do
        subject.update_membership_status

        expect(familienmitglied2_person.roles.count).to eq(2)
        expect(familienmitglied2_person.sac_membership.zusatzsektion_roles.first.end_on).to eq(end_of_next_year)
        expect(familienmitglied2_person.sac_membership.zusatzsektion_roles.first.beitragskategorie).to eq "adult"
      end

      it "doesn't create role for family members when person is not family main person" do
        allow(familienmitglied_person).to receive(:sac_family_main_person?).and_return(false)

        subject.update_membership_status

        expect(familienmitglied2_person.sac_membership.zusatzsektion_roles).to eq([])
      end
    end
  end
end
