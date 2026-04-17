# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Filter::Tour::MyPendingApprovals do
  # section_tour: bluemlisalp group, state: review, subito: false,
  # discipline: wanderweg (child of wandern), target_groups: kinder + familien.
  # Approval kinds in order: professional (1), security (2), editorial (3).
  let(:tour) { events(:section_tour) }
  let(:komitee) { groups(:bluemlisalp_freigabekomitee) }
  let(:person) { Fabricate(:person) }
  let(:base_scope) { Event::Tour.all }

  subject(:filter) { described_class.new(:my_pending_approvals, {active: "1"}) }

  before { Auth.current_person = person }

  def filtered
    filter.apply(base_scope)
  end

  def create_pruefer(approval_kinds:)
    Group::FreigabeKomitee::Pruefer.create!(group: komitee, person:, approval_kinds:)
  end

  def approve(kind, freigabe_komitee: komitee)
    tour.approvals.create!(
      approval_kind: event_approval_kinds(kind),
      approved: true,
      freigabe_komitee:,
      creator: people(:admin)
    )
  end

  context "filter activation" do
    it "is blank when active arg is missing" do
      inactive = described_class.new(:my_pending_approvals, {})
      expect(inactive).to be_blank
    end
  end

  context "state filter" do
    before { create_pruefer(approval_kinds: [event_approval_kinds(:professional)]) }

    it "includes tour in review state" do
      expect(filtered).to include(tour)
    end

    it "excludes tour in draft state" do
      tour.update!(state: :draft)
      expect(filtered).not_to include(tour)
    end

    it "excludes tour in approved state" do
      tour.update!(state: :approved)
      expect(filtered).not_to include(tour)
    end
  end

  context "when user has no Prüfer role" do
    it "excludes tour even when it is in review" do
      expect(filtered).not_to include(tour)
    end
  end

  context "when user is Prüfer for the lowest open approval kind" do
    before { create_pruefer(approval_kinds: [event_approval_kinds(:professional)]) }

    it "includes tour when no approvals exist yet (first kind is open)" do
      expect(filtered).to include(tour)
    end

    it "includes tour with child discipline normalized to parent" do
      # wanderweg (child) maps to wandern (parent) via COALESCE; responsibility is for wandern
      expect(filtered).to include(tour)
    end

    it "excludes tour when it is self approved" do
      tour.approvals.create!(approved: true)
      tour.update(state: :approved)
      expect(filtered).not_to include(tour)
    end
  end

  context "when user is Prüfer for the second kind and first is already approved" do
    before { create_pruefer(approval_kinds: [event_approval_kinds(:security)]) }

    it "includes tour when first kind is approved and second is open" do
      approve(:professional)
      expect(filtered).to include(tour)
    end

    it "excludes tour when first kind is still open (not yet user's turn)" do
      expect(filtered).not_to include(tour)
    end
  end

  context "when user is only Prüfer for a higher-order kind but lower ones are still open" do
    before { create_pruefer(approval_kinds: [event_approval_kinds(:editorial)]) }

    it "excludes tour when lower-order kinds are not yet approved" do
      expect(filtered).not_to include(tour)
    end

    it "includes tour when all lower-order kinds are approved" do
      approve(:professional)
      approve(:security)
      expect(filtered).to include(tour)
    end
  end

  context "when user's approval kind has already been approved" do
    before { create_pruefer(approval_kinds: [event_approval_kinds(:professional)]) }

    it "excludes tour when user's kind is already approved" do
      approve(:professional)
      expect(filtered).not_to include(tour)
    end
  end

  context "when all approval kinds are approved" do
    before do
      create_pruefer(approval_kinds: [event_approval_kinds(:professional)])
      approve(:professional)
      approve(:security)
      approve(:editorial)
    end

    it "excludes tour" do
      expect(filtered).not_to include(tour)
    end
  end

  context "when user has no approval kinds assigned" do
    it "excludes tour when Prüfer role has no approval kind" do
      Group::FreigabeKomitee::Pruefer.create!(group: komitee, person:, approval_kinds: [])
      expect(filtered).not_to include(tour)
    end
  end

  context "when a soft-deleted approval kind is at a lower order" do
    before { create_pruefer(approval_kinds: [event_approval_kinds(:security)]) }

    it "ignores deleted kinds when checking lowest open level" do
      event_approval_kinds(:professional).delete  # soft delete
      # Now security (order 2) is effectively the lowest non-deleted open kind
      expect(filtered).to include(tour)
    end
  end

  context "when user is Prüfer in a different sektion's komitee" do
    it "excludes tour" do
      other_komitee = groups(:bluemlisalp_ortsgruppe_ausserberg_freigabe_komitee)
      Group::FreigabeKomitee::Pruefer.create!(
        group: other_komitee, person:,
        approval_kinds: [event_approval_kinds(:professional)]
      )
      expect(filtered).not_to include(tour)
    end
  end

  context "with an inactive Prüfer role" do
    it "excludes tour when role is archived" do
      role = create_pruefer(approval_kinds: [event_approval_kinds(:professional)])
      role.update_columns(archived_at: 1.day.ago)

      expect(filtered).not_to include(tour)
    end

    it "excludes tour when role end_on is in the past" do
      create_pruefer(approval_kinds: [event_approval_kinds(:professional)]).update_columns(end_on: 1.day.ago)

      expect(filtered).not_to include(tour)
    end

    it "excludes tour when role start_on is in the future" do
      create_pruefer(approval_kinds: [event_approval_kinds(:professional)]).update!(start_on: 1.day.from_now)

      expect(filtered).not_to include(tour)
    end
  end
end
