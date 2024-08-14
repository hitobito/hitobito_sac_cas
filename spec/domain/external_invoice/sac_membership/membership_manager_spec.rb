# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe ExternalInvoice::SacMembership::MembershipManager do
  let(:date) { Time.zone.today.next_year.end_of_year }
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

  before do
    Role.update_all(delete_on: Time.zone.today.end_of_year)
  end

  context "link to stammsektions role" do
    context "adult" do
      subject { described_class.new(mitglied_person, groups(:bluemlisalp_mitglieder), date.year) }

      it "updates delete_on" do
        expect(count_roles_changed).to eq(2)

        expect(mitglied.delete_on).to eq(date)
        expect(mitglied_zweitsektion.reload.delete_on).to eq(date)
      end

      it "doesnt update delete_on when role is terminated" do
        mitglied_zweitsektion.update_column(:terminated, true)
        expect(count_roles_changed).to eq(1)
      end

      it "doesnt update roles when delete_on is already in external invoice year" do
        Role.update_all(delete_on: date)
        expect(count_roles_changed).to eq(0)
      end

      it "doesnt update roles when delete_on is after external invoice year" do
        Role.update_all(delete_on: date.next_year(5))
        expect(count_roles_changed).to eq(0)
      end
    end

    context "family" do
      subject { described_class.new(familienmitglied_person, groups(:bluemlisalp_mitglieder), date.year) }

      it "updates delete_on for all family member roles" do
        expect(count_roles_changed).to eq(6)

        expect(familienmitglied.delete_on).to eq(date)
        expect(familienmitglied_zweitsektion.delete_on).to eq(date)
        expect(familienmitglied2.delete_on).to eq(date)
        expect(familienmitglied2_zweitsektion.delete_on).to eq(date)
        expect(familienmitglied_kind.delete_on).to eq(date)
        expect(familienmitglied_kind_zweitsektion.delete_on).to eq(date)
      end

      it "only updates zusatzsektions role of family member when beitragskategorie is family" do
        # add role with adult beitragskategorie to family mitglied
        familienmitglied.person.sac_membership.zusatzsektion_roles.destroy_all
        mitglied_zweitsektion.update!(person: familienmitglied.person)

        expect(count_roles_changed).to eq(5)
      end

      it "only updates own roles when no family main person" do
        allow(familienmitglied_person).to receive(:sac_family_main_person?).and_return(false)
        expect(count_roles_changed).to eq(2)
      end
    end
  end

  context "link to self registration stammsektion role" do
    context "adult" do
      let(:new_member) do
        person = Fabricate(:person, birthday: Time.zone.today - 19.years)
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
          person: person,
          beitragskategorie: :adult,
          group: groups(:bluemlisalp_neuanmeldungen_nv))
        person
      end

      subject { described_class.new(new_member, groups(:bluemlisalp_neuanmeldungen_nv), date.year) }

      it "creates stammsektion role" do
        subject.update_membership_status

        expect(new_member.sac_membership.active?).to eq(true)
        expect(new_member.roles.count).to eq(1)
        expect(new_member.sac_membership.stammsektion_role.delete_on).to eq(Date.new(date.year).end_of_year)
      end
    end

    context "family" do
      before do
        Role.destroy_all
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

      subject { described_class.new(familienmitglied_person, groups(:bluemlisalp_neuanmeldungen_nv), date.year) }

      it "creates stammsektion role" do
        subject.update_membership_status

        expect(familienmitglied_person.sac_membership.active?).to eq(true)
        expect(familienmitglied2_person.sac_membership.active?).to eq(true)
        expect(familienmitglied_person.roles.count).to eq(1)
        expect(familienmitglied2_person.roles.count).to eq(1)
        expect(familienmitglied_person.sac_membership.stammsektion_role.delete_on).to eq(Date.new(date.year).end_of_year)
        expect(familienmitglied2_person.sac_membership.stammsektion_role.delete_on).to eq(Date.new(date.year).end_of_year)
      end

      it "doesnt create role for family members when person is not family main person" do
        allow(familienmitglied_person).to receive(:sac_family_main_person?).and_return(false)

        expect(familienmitglied2_person.sac_membership.active?).to eq(false)
      end
    end
  end

  context "link to self registration zusatzsektion roles" do
    context "adult" do
      before do
        mitglied_person.sac_membership.stammsektion_role.update(delete_on: Time.zone.today.next_year(5).end_of_year)
        mitglied_person.sac_membership.zusatzsektion_roles.destroy_all

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: mitglied_person,
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))
      end

      subject { described_class.new(mitglied_person, groups(:matterhorn_neuanmeldungen_nv), date.year) }

      it "creates zusatzsektions role" do
        subject.update_membership_status

        expect(mitglied_person.roles.count).to eq(2)
        expect(mitglied_person.sac_membership.zusatzsektion_roles.first.delete_on).to eq(Date.new(date.year).end_of_year)
      end
    end

    context "family" do
      before do
        familienmitglied_kind_person.destroy

        familienmitglied_person.sac_membership.stammsektion_role.update(delete_on: Time.zone.today.next_year(5).end_of_year)
        familienmitglied_person.sac_membership.zusatzsektion_roles.destroy_all
        familienmitglied2_person.sac_membership.stammsektion_role.update(delete_on: Time.zone.today.next_year(5).end_of_year)
        familienmitglied2_person.sac_membership.zusatzsektion_roles.destroy_all

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: familienmitglied_person,
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: familienmitglied2_person,
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))
      end

      subject { described_class.new(familienmitglied_person, groups(:matterhorn_neuanmeldungen_nv), date.year) }

      it "creates zusatzsektions roles for family members" do
        subject.update_membership_status

        expect(familienmitglied2_person.roles.count).to eq(2)
        expect(familienmitglied2_person.sac_membership.zusatzsektion_roles.first.delete_on).to eq(Date.new(date.year).end_of_year)
      end

      it "doesnt create role for family members when person is not family main person" do
        allow(familienmitglied_person).to receive(:sac_family_main_person?).and_return(false)

        subject.update_membership_status

        expect(familienmitglied2_person.sac_membership.zusatzsektion_roles).to eq([])
      end
    end
  end

  private

  def count_roles_changed
    role_dates_before = Role.all.map(&:delete_on)

    subject.update_membership_status

    role_dates_after = Role.all.map(&:delete_on)

    # check how many dates have changed
    role_dates_after.zip(role_dates_before).count { |a, b| a != b } + (role_dates_after.size - role_dates_before.size).abs
  end
end
