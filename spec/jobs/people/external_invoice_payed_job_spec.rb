# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::ExternalInvoicePayedJob < BaseJob do
  let(:date) { Time.zone.today.next_year.end_of_year }
  let(:mitglied) { roles(:mitglied) }
  let(:mitglied_zweitsektion) { roles(:mitglied_zweitsektion) }
  let(:familienmitglied) { roles(:familienmitglied) }
  let(:familienmitglied_zweitsektion) { roles(:familienmitglied_zweitsektion) }
  let(:familienmitglied2) { roles(:familienmitglied2) }
  let(:familienmitglied2_zweitsektion) { roles(:familienmitglied2_zweitsektion) }
  let(:familienmitglied_kind) { roles(:familienmitglied_kind) }
  let(:familienmitglied_kind_zweitsektion) { roles(:familienmitglied_kind_zweitsektion) }

  before do
    Role.update_all(delete_on: Time.zone.today.end_of_year)
  end

  context "link to stammsektions role" do
    context "adult" do
      subject(:job) { People::ExternalInvoicePayedJob.new(people(:mitglied), groups(:bluemlisalp_mitglieder), date.year) }

      it "updates delete_on" do
        expect(perform_payed_job).to eq(2)

        expect(mitglied.delete_on).to eq(date)
        expect(mitglied_zweitsektion.reload.delete_on).to eq(date)
      end

      it "doesnt update delete_on when role is terminated" do
        mitglied_zweitsektion.update_column(:terminated, true)
        expect(perform_payed_job).to eq(1)
      end

      it "doesnt update roles when delete_on is already in external invoice year" do
        Role.update_all(delete_on: date)
        expect(perform_payed_job).to eq(0)
      end

      it "doesnt update roles when delete_on is after external invoice year" do
        Role.update_all(delete_on: date.next_year(5))
        expect(perform_payed_job).to eq(0)
      end
    end

    context "family" do
      subject(:job) { People::ExternalInvoicePayedJob.new(people(:familienmitglied), groups(:bluemlisalp_mitglieder), date.year) }

      it "updates delete_on for all family member roles" do
        expect(perform_payed_job).to eq(6)

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

        expect(perform_payed_job).to eq(5)
      end

      it "only updates own roles when no family main person" do
        allow(people(:familienmitglied)).to receive(:sac_family_main_person?).and_return(false)
        expect(perform_payed_job).to eq(2)
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

      subject(:job) { People::ExternalInvoicePayedJob.new(new_member, groups(:bluemlisalp_neuanmeldungen_nv), date.year) }

      it "creates stammsektion role" do
        job.perform

        expect(new_member.sac_membership.active?).to eq(true)
        expect(new_member.roles.count).to eq(1)
        expect(new_member.sac_membership.stammsektion_role.delete_on).to eq(Date.new(date.year).end_of_year)
      end
    end

    context "family" do
      before do
        Role.destroy_all
        people(:familienmitglied_kind).destroy

        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
          person: people(:familienmitglied),
          beitragskategorie: :family,
          created_at: 1.year.ago,
          group: groups(:bluemlisalp_neuanmeldungen_nv))

        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
          person: people(:familienmitglied2),
          beitragskategorie: :family,
          created_at: 1.year.ago,
          group: groups(:bluemlisalp_neuanmeldungen_nv))
      end

      subject(:job) { People::ExternalInvoicePayedJob.new(people(:familienmitglied), groups(:bluemlisalp_neuanmeldungen_nv), date.year) }

      it "creates stammsektion role" do
        job.perform

        expect(people(:familienmitglied).sac_membership.active?).to eq(true)
        expect(people(:familienmitglied2).sac_membership.active?).to eq(true)
        expect(people(:familienmitglied).roles.count).to eq(1)
        expect(people(:familienmitglied2).roles.count).to eq(1)
        expect(people(:familienmitglied).sac_membership.stammsektion_role.delete_on).to eq(Date.new(date.year).end_of_year)
        expect(people(:familienmitglied2).sac_membership.stammsektion_role.delete_on).to eq(Date.new(date.year).end_of_year)
      end

      it "doesnt create role for family members when person is not family main person" do
        allow(people(:familienmitglied)).to receive(:sac_family_main_person?).and_return(false)

        expect(people(:familienmitglied2).sac_membership.active?).to eq(false)
      end
    end
  end

  context "link to self registration zusatzsektion roles" do
    context "adult" do
      before do
        people(:mitglied).sac_membership.stammsektion_role.update(delete_on: Time.zone.today.next_year(5).end_of_year)
        people(:mitglied).sac_membership.zusatzsektion_roles.destroy_all

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: people(:mitglied),
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))
      end

      subject(:job) { People::ExternalInvoicePayedJob.new(people(:mitglied), groups(:matterhorn_neuanmeldungen_nv), date.year) }

      it "creates zusatzsektions role" do
        job.perform

        expect(people(:mitglied).roles.count).to eq(2)
        expect(people(:mitglied).sac_membership.zusatzsektion_roles.first.delete_on).to eq(Date.new(date.year).end_of_year)
      end
    end

    context "family" do
      before do
        people(:familienmitglied_kind).destroy

        people(:familienmitglied).sac_membership.stammsektion_role.update(delete_on: Time.zone.today.next_year(5).end_of_year)
        people(:familienmitglied).sac_membership.zusatzsektion_roles.destroy_all
        people(:familienmitglied2).sac_membership.stammsektion_role.update(delete_on: Time.zone.today.next_year(5).end_of_year)
        people(:familienmitglied2).sac_membership.zusatzsektion_roles.destroy_all

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: people(:familienmitglied),
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
          person: people(:familienmitglied2),
          beitragskategorie: :adult,
          group: groups(:matterhorn_neuanmeldungen_nv))
      end

      subject(:job) { People::ExternalInvoicePayedJob.new(people(:familienmitglied), groups(:matterhorn_neuanmeldungen_nv), date.year) }

      it "creates zusatzsektions roles for family members" do
        job.perform

        expect(people(:familienmitglied2).roles.count).to eq(2)
        expect(people(:familienmitglied2).sac_membership.zusatzsektion_roles.first.delete_on).to eq(Date.new(date.year).end_of_year)
      end

      it "doesnt create role for family members when person is not family main person" do
        allow(people(:familienmitglied)).to receive(:sac_family_main_person?).and_return(false)

        job.perform

        expect(people(:familienmitglied2).sac_membership.zusatzsektion_roles).to eq([])
      end
    end
  end

  private

  def perform_payed_job
    role_dates_before_job_run = Role.all.map(&:delete_on)

    job.perform

    role_dates_after_job_run = Role.all.map(&:delete_on)

    # check how many dates have changed
    role_dates_after_job_run.zip(role_dates_before_job_run).count { |a, b| a != b } + (role_dates_after_job_run.size - role_dates_before_job_run.size).abs
  end
end
