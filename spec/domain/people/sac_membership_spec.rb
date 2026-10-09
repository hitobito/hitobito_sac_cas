# frozen_string_literal: true

#  Copyright (c) 2023-2026, Schweizer Alpen-Club. This file is part of
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

  describe "#zusatzsektion_roles" do
    it "returns empty without zusatzsektion role" do
      expect(membership.zusatzsektion_roles).to be_empty
    end

    context "with zusatzsektion role" do
      let(:person) { people(:mitglied) }

      it "returns the zusatzsektion roles" do
        expect(membership.zusatzsektion_roles).to contain_exactly(roles(:mitglied_zweitsektion))
      end
    end
  end

  describe "#zusatzsektionen" do
    it "returns empty without zusatzsektion role" do
      expect(membership.zusatzsektionen).to be_empty
    end

    context "with zusatzsektion role" do
      let(:person) { people(:mitglied) }

      it "returns layer group of all zusatzsektion roles" do
        expect(membership.zusatzsektionen).to contain_exactly(groups(:matterhorn))
      end
    end
  end

  describe "#mitglied?" do
    let(:mitglieder) { groups(:bluemlisalp_mitglieder) }
    let(:von) { Time.zone.now.beginning_of_year }
    let(:bis) { Time.zone.today.end_of_year }

    def create_role(role_type, group: mitglieder, start_on: von, end_on: bis, validate: true)
      role = Fabricate.build(role_type.sti_name,
        person: person, group: group, start_on: start_on, end_on: end_on,
        beitragskategorie: "adult")
      # skip validations as these states are invalid in the domain, but reachable in legacy data.
      # beitragskategorie is passed in explicitly, as the callback setting it is skipped as well.
      validate ? role.save! : role.save!(validate: false)
    end

    it "is false without any role" do
      expect(membership).not_to be_mitglied
    end

    it "is true with active stammsektion role" do
      create_role(Group::SektionsMitglieder::Mitglied)

      expect(membership).to be_mitglied
    end

    it "is true with active zusatzsektion role only" do
      # a bare zusatzsektion role is invalid, it always exists next to a stammsektion role
      create_role(Group::SektionsMitglieder::MitgliedZusatzsektion,
        group: groups(:matterhorn_mitglieder), validate: false)

      expect(membership).to be_mitglied
    end

    it "is false with terminated stammsektion role" do
      create_role(Group::SektionsMitglieder::Mitglied, end_on: 1.day.ago)

      expect(membership).not_to be_mitglied
    end

    it "is false with future stammsektion role" do
      create_role(Group::SektionsMitglieder::Mitglied, start_on: 1.month.from_now)

      expect(membership).not_to be_mitglied
    end

    it "is false with active neuanmeldung role only" do
      create_role(Group::SektionsNeuanmeldungenSektion::Neuanmeldung, group: neuanmeldungen_sektion)

      expect(membership).not_to be_mitglied
    end

    it "is false with active sektions ehrenmitglied role only" do
      create_role(Group::SektionsMitglieder::Ehrenmitglied, validate: false)

      expect(membership).not_to be_mitglied
    end

    it "is false with active sektions beguenstigt role only" do
      create_role(Group::SektionsMitglieder::Beguenstigt, validate: false)

      expect(membership).not_to be_mitglied
    end
  end
end
