# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::Neuanmeldungen::Approve do
  include ActiveJob::TestHelper

  let(:neuanmeldung_role_class) { Group::SektionsNeuanmeldungenSektion::Neuanmeldung }
  let(:neuanmeldung_approved_role_class) { Group::SektionsNeuanmeldungenNv::Neuanmeldung }

  let(:sektion) { groups(:bluemlisalp) }
  let(:neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:neuanmeldungen_nv) { groups(:bluemlisalp_neuanmeldungen_nv) }

  def create_role(beitragskategorie, person: Fabricate(:person, birthday: 20.years.ago, sac_family_main_person: true), type: neuanmeldung_role_class)
    Fabricate(
      type.sti_name,
      group: neuanmeldungen_sektion,
      beitragskategorie: beitragskategorie,
      created_at: Time.zone.now.beginning_of_year,
      person: person
    )
  end

  def expect_role(role, expected_role_class, expected_group)
    roles = role.person.reload.roles.where.not(type: Group::SektionsMitglieder::Mitglied.sti_name)
    expect(roles).to have(1).item
    actual_role = roles.first
    expect(actual_role).to be_a expected_role_class
    expect(actual_role.group).to eq expected_group
    expect(actual_role.beitragskategorie).to eq role.beitragskategorie
  end

  it "replaces the neuanmeldungen_sektion roles with neuanmeldungen_nv roles" do
    neuanmeldungen = [:adult, :adult, :youth, :family].map { |cat| create_role(cat) }

    approver = described_class.new(
      group: neuanmeldungen_sektion,
      people_ids: [
        neuanmeldungen.first.person.id,
        neuanmeldungen.third.person.id,
        neuanmeldungen.fourth.person.id
      ]
    )

    expect { approver.call }
      .to change { neuanmeldung_role_class.count }.by(-3)
      .and change { neuanmeldung_approved_role_class.count }.by(3)
      .and change { ExternalInvoice::SacMembership.count }.by(3)
      .and change { Delayed::Job.where("handler like '%CreateMembershipInvoiceJob%'").count }.by(3)
      .and have_enqueued_mail(People::NeuanmeldungenMailer, :approve).with(neuanmeldungen.first.person, sektion)
      .and have_enqueued_mail(People::NeuanmeldungenMailer, :approve).with(neuanmeldungen.third.person, sektion)
      .and have_enqueued_mail(People::NeuanmeldungenMailer, :approve).with(neuanmeldungen.fourth.person, sektion)

    expect_role(neuanmeldungen.first, neuanmeldung_approved_role_class, neuanmeldungen_nv)
    expect_role(neuanmeldungen.third, neuanmeldung_approved_role_class, neuanmeldungen_nv)
    expect_role(neuanmeldungen.fourth, neuanmeldung_approved_role_class, neuanmeldungen_nv)

    expect_role(neuanmeldungen.second, neuanmeldung_role_class, neuanmeldungen_sektion)
    expect(ExternalInvoice::SacMembership.find_by(person_id: neuanmeldungen.second.id)).to be_nil
  end

  context "Zusatzsektion" do
    let(:neuanmeldung_role_class) { Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion }
    let(:neuanmeldung_approved_role_class) { Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion }

    it "replaces the neuanmeldungen_zusatzsektion roles with neuanmeldungen_zusatzsektion_nv roles" do
      neuanmeldungen = [:adult, :adult, :youth, :family].map do |cat|
        person = Fabricate(:person, sac_family_main_person: true)
        Fabricate(
          Group::SektionsMitglieder::Mitglied.sti_name,
          group: groups(:matterhorn_mitglieder),
          person: person,
          start_on: 2.years.ago.beginning_of_year
        )
        create_role(cat, person: person).tap { |r| r.update_columns(start_on: 1.day.ago) }
      end

      approver = described_class.new(
        group: neuanmeldungen_sektion,
        people_ids: [
          neuanmeldungen.first.person.id,
          neuanmeldungen.third.person.id,
          neuanmeldungen.fourth.person.id
        ]
      )

      expect { approver.call }
        .to change { neuanmeldung_role_class.count }.by(-3)
        .and change { neuanmeldung_approved_role_class.count }.by(3)
        .and change { ExternalInvoice::SacMembership.count }.by(3)
        .and change { Delayed::Job.where("handler like '%CreateMembershipInvoiceJob%'").count }.by(3)
        .and have_enqueued_mail(People::NeuanmeldungenMailer, :approve).with(neuanmeldungen.first.person, sektion)
        .and have_enqueued_mail(People::NeuanmeldungenMailer, :approve).with(neuanmeldungen.third.person, sektion)
        .and have_enqueued_mail(People::NeuanmeldungenMailer, :approve).with(neuanmeldungen.fourth.person, sektion)

      expect_role(neuanmeldungen.first, neuanmeldung_approved_role_class, neuanmeldungen_nv)
      expect_role(neuanmeldungen.third, neuanmeldung_approved_role_class, neuanmeldungen_nv)
      expect_role(neuanmeldungen.fourth, neuanmeldung_approved_role_class, neuanmeldungen_nv)

      expect_role(neuanmeldungen.second, neuanmeldung_role_class, neuanmeldungen_sektion)
      expect(ExternalInvoice::SacMembership.find_by(person_id: neuanmeldungen.second.id)).to be_nil
    end
  end

  it "doesn't create invoice or send email for person in family when not main person" do
    people(:familienmitglied2).roles.destroy_all
    neuanmeldung = create_role(:family, person: people(:familienmitglied2))

    expect { described_class.new(group: neuanmeldungen_sektion, people_ids: [neuanmeldung.person.id]).call }
      .to not_change { ExternalInvoice::SacMembership.count }
      .and not_change { Delayed::Job.where("handler like '%CreateMembershipInvoiceJob%'").count }
      .and not_have_enqueued_mail(People::NeuanmeldungenMailer)
  end

  it "creates the SektionNeuanmeldungNv group if it does not exist" do
    neuanmeldungen_nv.destroy!
    neuanmeldung = create_role(:adult)

    described_class.new(group: neuanmeldungen_sektion, people_ids: [neuanmeldung.person.id]).call

    expect { neuanmeldung.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(neuanmeldung.person.roles).to have(1).item
    actual_role = neuanmeldung.person.roles.first
    expect(actual_role).to be_a neuanmeldung_approved_role_class
    expect(actual_role.group).to be_a Group::SektionsNeuanmeldungenNv
    expect(actual_role.group.parent_id).to eq sektion.id
    expect(actual_role.group.id).not_to eq neuanmeldungen_nv.id
  end

  describe "email and invoice" do
    let(:person) { neuanmeldung.person }
    let(:neuanmeldung) { create_role(:adult) }
    let(:approver) { described_class.new(group: neuanmeldungen_sektion, people_ids: [person.id]) }

    it "send an email and invoice to person" do
      expect { approver.call }.to change { ExternalInvoice::SacMembership.count }.by(1)
        .and change { Delayed::Job.where("handler like '%CreateMembershipInvoiceJob%'").count }.by(1)
        .and have_enqueued_mail(People::NeuanmeldungenMailer, :approve).with(person, sektion)
    end

    context "family" do
      let(:neuanmeldung) { create_role(:family) }

      it "send an email to main person of family" do
        person.update_columns(sac_family_main_person: true)
        expect { approver.call }.to change { ExternalInvoice::SacMembership.count }.by(1)
          .and change { Delayed::Job.where("handler like '%CreateMembershipInvoiceJob%'").count }.by(1)
          .and have_enqueued_mail(People::NeuanmeldungenMailer, :approve).with(person, sektion)
      end

      it "considers both family members but creates invoice and sends email only once" do
        other = create_role(:family).person
        Person.where(id: [person.id, other.id]).update_all(household_key: "test")
        person.update_columns(sac_family_main_person: false)
        expect { approver.call }.to change { Group::SektionsNeuanmeldungenNv::Neuanmeldung.count }.by(2)
          .and change { Delayed::Job.where("handler like '%CreateMembershipInvoiceJob%'").count }.by(1)
          .and have_enqueued_mail(People::NeuanmeldungenMailer, :approve).with(other, sektion)
      end
    end
  end
end
