# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::SacMemberships::MembershipManager do
  include ActiveJob::TestHelper

  let(:end_of_next_year) { Time.zone.today.next_year.end_of_year }
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
  let(:sac_membership) { subject.person.sac_membership }

  before do
    ehrenmitglieder_group = Group::Ehrenmitglieder.create!(name: "Ehrenmitglieder", parent: groups(:root))
    Fabricate(:role, type: Group::SektionsMitglieder::Ehrenmitglied.sti_name, group: groups(:bluemlisalp_mitglieder), person: mitglied_person)
    Fabricate(:role, type: Group::SektionsMitglieder::Beguenstigt.sti_name, group: groups(:bluemlisalp_mitglieder), person: mitglied_person)
    Fabricate(:role, type: Group::Ehrenmitglieder::Ehrenmitglied.sti_name, group: ehrenmitglieder_group, person: mitglied_person)
    Fabricate(:role, type: Group::SektionsMitglieder::Ehrenmitglied.sti_name, group: groups(:bluemlisalp_mitglieder), person: familienmitglied_person)
    Fabricate(:role, type: Group::SektionsMitglieder::Beguenstigt.sti_name, group: groups(:bluemlisalp_mitglieder), person: familienmitglied_person)
    Fabricate(:role, type: Group::Ehrenmitglieder::Ehrenmitglied.sti_name, group: ehrenmitglieder_group, person: familienmitglied_person)
    Fabricate(:role, type: Group::SektionsMitglieder::Ehrenmitglied.sti_name, group: groups(:bluemlisalp_mitglieder), person: familienmitglied2_person)
    Fabricate(:role, type: Group::SektionsMitglieder::Beguenstigt.sti_name, group: groups(:bluemlisalp_mitglieder), person: familienmitglied2_person)
    Fabricate(:role, type: Group::Ehrenmitglieder::Ehrenmitglied.sti_name, group: ehrenmitglieder_group, person: familienmitglied2_person)
    Fabricate(:role, type: Group::SektionsMitglieder::Ehrenmitglied.sti_name, group: groups(:bluemlisalp_mitglieder), person: familienmitglied_kind_person)
    Fabricate(:role, type: Group::SektionsMitglieder::Beguenstigt.sti_name, group: groups(:bluemlisalp_mitglieder), person: familienmitglied_kind_person)
    Fabricate(:role, type: Group::Ehrenmitglieder::Ehrenmitglied.sti_name, group: ehrenmitglieder_group, person: familienmitglied_kind_person)
    Role.update_all(end_on: Time.zone.today.end_of_year)
  end

  it "does not fail if running without any actual work todo" do
    manager = described_class.new(Fabricate(:person), bluemlisalp, end_of_next_year.year)
    expect { manager.update_membership_status }.not_to raise_error
  end

  context "person has stammsektions role" do
    def updated_roles_count
      role_dates_before = Role.all.map(&:end_on)

      subject.update_membership_status

      role_dates_after = Role.all.map(&:end_on)

      # check how many dates have changed
      role_dates_after.zip(role_dates_before).count { |a, b| a != b } + (role_dates_after.size - role_dates_before.size).abs
    end

    context "adult" do
      subject { described_class.new(mitglied_person, bluemlisalp, end_of_next_year.year) }

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
    end

    context "family" do
      subject { described_class.new(familienmitglied_person, bluemlisalp, end_of_next_year.year) }

      it "updates end_on for all family member roles" do
        expect(updated_roles_count).to eq(15)

        expect(familienmitglied_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
        expect(familienmitglied2_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
        expect(familienmitglied_kind_person.roles.reload.map(&:end_on)).to all(eq(end_of_next_year))
      end

      it "only updates zusatzsektions role of family member when beitragskategorie is family" do
        # add role with adult beitragskategorie to family mitglied
        familienmitglied.person.sac_membership.zusatzsektion_roles.destroy_all
        mitglied_zweitsektion.update!(person: familienmitglied.person)

        expect(updated_roles_count).to eq(14)
      end

      it "only updates own roles when no family main person" do
        allow(familienmitglied_person).to receive(:sac_family_main_person?).and_return(false)
        expect(updated_roles_count).to eq(5)
      end
    end
  end

  context "person has expired stammsektions role" do
    let(:end_of_year) { Date.current.end_of_year }

    def check_new_membership_role_dates_and_groups(person)
      expect(sac_membership.active?).to be_truthy
      expect(sac_membership.stammsektion_role.start_on).to eq Time.zone.today
      expect(sac_membership.stammsektion_role.end_on).to eq end_of_year
      expect(sac_membership.zusatzsektion_roles.first.start_on).to eq Time.zone.today
      expect(sac_membership.zusatzsektion_roles.first.end_on).to eq end_of_year
      expect(sac_membership.membership_prolongable_roles.first.start_on).to eq Time.zone.today
      expect(sac_membership.membership_prolongable_roles.first.end_on).to eq end_of_year
      expect(sac_membership.membership_prolongable_roles.second.start_on).to eq Time.zone.today
      expect(sac_membership.membership_prolongable_roles.second.end_on).to eq end_of_year
      expect(sac_membership.membership_prolongable_roles.third.start_on).to eq Time.zone.today
      expect(sac_membership.membership_prolongable_roles.third.end_on).to eq end_of_year
    end

    context "adult" do
      subject { described_class.new(mitglied_person, bluemlisalp, end_of_year.year) }

      before do
        mitglied.update_column(:end_on, Time.zone.today.yesterday)
        mitglied_zweitsektion.update_column(:end_on, Time.zone.today.yesterday)
        mitglied_person.sac_membership.membership_prolongable_roles.update_all(end_on: Time.zone.today.yesterday)
      end

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
      subject { described_class.new(familienmitglied_person, bluemlisalp, end_of_year.year) }

      before do
        familienmitglied.update_column(:end_on, Time.zone.today.yesterday)
        familienmitglied_zweitsektion.update_column(:end_on, Time.zone.today.yesterday)
        familienmitglied_person.sac_membership.membership_prolongable_roles.update_all(end_on: Time.zone.today.yesterday)
        familienmitglied2.update_column(:end_on, Time.zone.today.yesterday)
        familienmitglied2_zweitsektion.update_column(:end_on, Time.zone.today.yesterday)
        familienmitglied2_person.sac_membership.membership_prolongable_roles.update_all(end_on: Time.zone.today.yesterday)
        familienmitglied_kind.update_column(:end_on, Time.zone.today.yesterday)
        familienmitglied_kind_zweitsektion.update_column(:end_on, Time.zone.today.yesterday)
        familienmitglied_kind_person.sac_membership.membership_prolongable_roles.update_all(end_on: Time.zone.today.yesterday)
      end

      it "creates new stammsektion role for person starting today" do
        expect do
          subject.update_membership_status
        end.to change { Role.count }.by(15)

        check_new_membership_role_dates_and_groups(familienmitglied_person)
        check_new_membership_role_dates_and_groups(familienmitglied2_person)
        check_new_membership_role_dates_and_groups(familienmitglied_kind_person)
      end

      it "does not create zusatzsektion roles for family members when only main person is in zusatzsektionen" do
        familienmitglied2_zweitsektion.destroy!
        familienmitglied_kind_zweitsektion.destroy!
        expect do
          subject.update_membership_status
        end.to change { Role.count }.by(13)
          .and change { familienmitglied2_person.sac_membership.zusatzsektion_roles.count }.by(0)
          .and change { familienmitglied_kind_person.sac_membership.zusatzsektion_roles.count }.by(0)
      end

      it "only creates zusatzsektions role of family member when beitragskategorie is family" do
        # add role with adult beitragskategorie to family mitglied
        People::SacMembership.new(familienmitglied2_person, date: Time.zone.today.yesterday).zusatzsektion_roles.destroy_all
        mitglied_zweitsektion.update!(person: familienmitglied2.person, end_on: Time.zone.today.yesterday)

        expect do
          subject.update_membership_status
        end.to change { Role.count }.by(14)
          .and change { familienmitglied2_person.sac_membership.zusatzsektion_roles.count }.by(0)
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

      subject { described_class.new(new_member, groups(:bluemlisalp_neuanmeldungen_nv), end_of_next_year.year) }

      it "creates stammsektion role and enqueues SacMembershipsMailer" do
        expect { subject.update_membership_status }.to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation).once
        expect(new_member.confirmed_at).to be_within(2.seconds).of(Time.zone.now)
        expect(new_member.sac_membership.active?).to eq(true)
        expect(new_member.roles.count).to eq(1)
        expect(new_member.sac_membership.stammsektion_role.end_on).to eq(end_of_next_year)
      end

      it "does not enqueue SacMembershipsMailer if person has no email" do
        new_member.update(email: nil)
        expect { subject.update_membership_status }.not_to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation)
        expect(new_member.sac_membership.stammsektion_role.end_on).to eq(end_of_next_year)
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

      subject { described_class.new(familienmitglied_person, bluemlisalp, end_of_next_year.year) }

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
        mitglied_person.sac_membership.stammsektion_role.update(end_on: end_of_next_year + 5.years)
        mitglied_person.sac_membership.zusatzsektion_roles.destroy_all
        mitglied_person.sac_membership.membership_prolongable_roles.destroy_all

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: mitglied_person,
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))
      end

      subject { described_class.new(mitglied_person, matterhorn, end_of_next_year.year) }

      it "creates zusatzsektions role and enqueues SacMembershipsMailer" do
        expect { subject.update_membership_status }.to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation).once

        expect(mitglied_person.roles.count).to eq(2)
        expect(mitglied_person.sac_membership.zusatzsektion_roles.first.end_on).to eq(end_of_next_year)
      end

      it "does not enqueue SacMembershipsMailer if person has no email" do
        mitglied_person.update(email: nil)
        expect { subject.update_membership_status }.not_to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation)
        expect(mitglied_person.sac_membership.zusatzsektion_roles.first.end_on).to eq(end_of_next_year)
      end

      it "only creates zusatzsektion for layer in question if two roles exist" do
        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: mitglied_person,
          beitragskategorie: :adult,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv))

        expect { subject.update_membership_status }.to have_enqueued_mail(Invoices::SacMembershipsMailer, :confirmation).once

        expect(mitglied_person.roles.count).to eq(3)
        expect(mitglied_person.sac_membership.zusatzsektion_roles.count).to eq 1
        expect(mitglied_person.sac_membership.zusatzsektion_roles.first.group.layer_group).to eq matterhorn
      end

      context "with stammsektions only partially covering year" do
        let(:stammsektion_end_on) { Date.new(2025, 5, 1) }

        before { mitglied.update_columns(end_on: stammsektion_end_on) }

        it "creates zusatzsektion role from today to end of stammsektion role" do
          travel_to(Date.new(2025, 1, 3)) { subject.update_membership_status }
          expect(mitglied_person.sac_membership.zusatzsektion_roles.first.start_on).to eq Date.new(2025, 1, 3)
          expect(mitglied_person.sac_membership.zusatzsektion_roles.first.end_on).to eq stammsektion_end_on
        end

        it "creates inactive role if run on after stammsektion expires" do
          travel_to(Date.new(2025, 5, 1)) { subject.update_membership_status }
          expect(mitglied_person.sac_membership.zusatzsektion_roles).to be_empty
          inactive_role = mitglied_person.roles.with_inactive.find_by(type: "Group::SektionsMitglieder::MitgliedZusatzsektion")
          expect(inactive_role.start_on).to eq stammsektion_end_on
          expect(inactive_role.end_on).to eq stammsektion_end_on
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

      subject { described_class.new(familienmitglied_person, groups(:matterhorn_neuanmeldungen_nv), end_of_next_year.year) }

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
