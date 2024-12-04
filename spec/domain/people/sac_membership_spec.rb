# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::SacMembership do
  let(:person) { Fabricate(:person, birthday: Time.zone.today - 42.years) }
  let(:neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }

  subject(:membership) { described_class.new(person) }

  context "without any role" do
    let(:person) { Fabricate.build(:person) }

    it "is not active" do
      expect(membership).not_to be_active
    end

    it "is not anytime" do
      expect(membership).not_to be_anytime
    end
  end

  context "with irrelevant role" do
    before do
      Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.name,
        person: person,
        group: neuanmeldungen_sektion,
        start_on: Time.zone.now.beginning_of_year,
        end_on: Time.zone.today.end_of_year)
    end

    it "is not active" do
      expect(membership).not_to be_active
    end

    it "is not anytime" do
      expect(membership).not_to be_anytime
    end
  end

  context "with active role" do
    before do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
        person: person,
        group: groups(:bluemlisalp_mitglieder),
        start_on: Time.zone.now.beginning_of_year,
        end_on: Time.zone.today.end_of_year)
    end

    it "is active" do
      expect(membership).to be_active
    end

    it "is anytime" do
      expect(membership).to be_anytime
    end
  end

  context "with future role" do
    before do
      person.roles.create!(
        type: Group::SektionsMitglieder::Mitglied.sti_name,
        group: groups(:bluemlisalp_mitglieder),
        start_on: 1.month.from_now,
        end_on: 1.month.from_now.end_of_year
      )
    end

    it "is not active" do
      expect(membership).not_to be_active
    end

    it "is anytime" do
      expect(membership).to be_anytime
    end
  end

  context "with past role" do
    before do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
        person: person,
        group: groups(:bluemlisalp_mitglieder),
        start_on: Time.zone.now.beginning_of_year,
        end_on: 1.day.ago)
    end

    it "is not active" do
      expect(membership).not_to be_active
    end

    it "is anytime" do
      expect(membership).to be_anytime
    end
  end

  describe "#active_in?" do
    let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder) }

    it "only considers roles in same layer" do
      person.roles.create!(
        type: Group::SektionsMitglieder::Mitglied,
        group: group,
        start_on: Time.zone.now.beginning_of_year,
        end_on: Time.zone.today.end_of_year
      )
      expect(membership.active_in?(groups(:bluemlisalp_ortsgruppe_ausserberg))).to eq true
      expect(membership.active_in?(groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder))).to eq false
      expect(membership.active_in?(groups(:bluemlisalp))).to eq false
      expect(membership.active_in?(groups(:matterhorn))).to eq false
    end

    it "ignores future and past roles" do
      person.roles.create!(
        type: Group::SektionsMitglieder::Mitglied,
        group: group,
        start_on: 1.year.ago,
        end_on: 1.month.ago
      )
      person.roles.create!(
        type: Group::SektionsMitglieder::Mitglied,
        group: group,
        start_on: 1.month.from_now,
        end_on: 1.year.from_now
      )
      expect(membership.active_in?(groups(:bluemlisalp))).to eq false
      expect(membership.active_in?(groups(:matterhorn))).to eq false
      expect(membership.active_in?(groups(:bluemlisalp_ortsgruppe_ausserberg))).to eq false
    end
  end

  describe "#active_or_approvable_in?" do
    let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder) }

    it "considers active membership" do
      person.roles.create!(
        type: Group::SektionsMitglieder::Mitglied,
        group: group,
        start_on: Time.zone.now.beginning_of_year,
        end_on: Time.zone.today.end_of_year
      )
      expect(membership.active_or_approvable_in?(groups(:bluemlisalp_ortsgruppe_ausserberg))).to eq true
      expect(membership.active_or_approvable_in?(groups(:bluemlisalp))).to eq false
    end

    it "considers approvable membership" do
      person.roles.create!(
        type: Group::SektionsNeuanmeldungenNv::Neuanmeldung,
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv),
        start_on: Time.zone.now.beginning_of_year,
        end_on: Time.zone.today.end_of_year
      )
      expect(membership.active_or_approvable_in?(groups(:bluemlisalp_ortsgruppe_ausserberg))).to eq true
      expect(membership.active_or_approvable_in?(groups(:bluemlisalp))).to eq false
    end
  end

  describe "#invoice?" do
    it "is false for non member" do
      expect_invoice(people(:admin), false)
    end

    it "is true for neuanmeldung" do
      person = people(:admin)
      Fabricate(::Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name,
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv),
        person: person,
        beitragskategorie: :adult)
      expect_invoice(person, true)
    end

    it "is true for member" do
      expect_invoice(people(:mitglied), true)
    end

    it "is true for main family person" do
      expect_invoice(people(:familienmitglied), true)
    end

    it "is false for family child" do
      expect_invoice(people(:familienmitglied_kind), false)
    end

    it "is true for family child with individual zusatzsektion" do
      person = people(:familienmitglied_kind)
      Fabricate(::Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name,
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv),
        person: person,
        beitragskategorie: :youth)
      expect_invoice(person, true)
    end

    def expect_invoice(person, value)
      expect(person.sac_membership.invoice?).to eq(value)
      expect(People::SacMembership.new(person, in_memory: true).invoice?).to eq(value)
    end
  end
end
