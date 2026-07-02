# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Filter::Tour::MyApprovalResponsibilities do
  # section_tour: bluemlisalp group, subito: false, activity: wanderweg (child of wandern),
  # target_groups: kinder + familien. All covered by bluemlisalp_wandern_* responsibilities.
  let(:tour) { events(:section_tour) }
  let(:komitee) { groups(:bluemlisalp_freigabekomitee) }
  let(:person) { Fabricate(:person) }
  let(:base_scope) { Event::Tour.all }

  subject(:filter) { described_class.new(:my_approval_responsibilities, {active: "1"}) }

  before { allow(Auth).to receive(:current_person).and_return(person) }

  def filtered
    filter.apply(base_scope)
  end

  def create_pruefer(group: komitee, approval_kinds: [event_approval_kinds(:professional)])
    Group::FreigabeKomitee::Pruefer.create!(group:, person:, approval_kinds:)
  end

  context "filter activation" do
    it "is blank and passes scope through when active arg is missing" do
      inactive = described_class.new(:my_approval_responsibilities, {})
      expect(inactive).to be_blank
    end

    it "is blank and passes scope through when active is '0'" do
      inactive = described_class.new(:my_approval_responsibilities, {active: "0"})
      expect(inactive).to be_blank
    end
  end

  context "when user has no Prüfer role" do
    it "excludes tour" do
      expect(filtered).not_to include(tour)
    end
  end

  context "when user is Prüfer in responsible komitee" do
    before { create_pruefer }

    it "includes tour in review state" do
      expect(filtered).to include(tour)
    end

    it "includes tour in draft state" do
      tour.update!(state: :draft)
      expect(filtered).to include(tour)
    end

    it "includes tour in approved state" do
      tour.update!(state: :approved)
      expect(filtered).to include(tour)
    end

    it "includes tour with child activity normalized to parent" do
      # wanderweg (child) maps to wandern (parent) via COALESCE; responsibility is for wandern
      expect(filtered).to include(tour)
    end
  end

  context "when user is Prüfer in a komitee from a different sektion" do
    it "excludes tour" do
      other_komitee = groups(:bluemlisalp_ortsgruppe_ausserberg_freigabe_komitee)
      create_pruefer(group: other_komitee)

      expect(filtered).not_to include(tour)
    end
  end

  context "when tour has no matching responsibility for its activity" do
    let!(:unknown_activity) { Fabricate(:event_activity) }
    let!(:unmatched_tour) do
      Fabricate(:sac_tour,
        groups: [groups(:bluemlisalp)],
        activities: [unknown_activity],
        target_groups: [event_target_groups(:kinder)])
    end

    before { create_pruefer }

    it "excludes tour whose activity has no responsibility" do
      # bluemlisalp_freigabekomitee has no responsibility for unknown_activity
      expect(filtered).not_to include(unmatched_tour)
    end

    it "still includes tour whose activity is covered" do
      expect(filtered).to include(tour)
    end
  end

  context "with an inactive Prüfer role" do
    it "excludes tour when role is archived" do
      role = create_pruefer
      role.update_columns(archived_at: 1.day.ago)

      expect(filtered).not_to include(tour)
    end

    it "excludes tour when role end_on is in the past" do
      create_pruefer.update_columns(end_on: 1.day.ago)

      expect(filtered).not_to include(tour)
    end

    it "excludes tour when role start_on is in the future" do
      create_pruefer.update!(start_on: 1.day.from_now)

      expect(filtered).not_to include(tour)
    end

    it "includes tour when role end_on is today" do
      create_pruefer.update!(end_on: Date.current)

      expect(filtered).to include(tour)
    end
  end
end
