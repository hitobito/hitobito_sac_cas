# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Filter::Tour::Approval do
  # section_tour: bluemlisalp group, state: review, subito: false,
  # discipline: wanderweg (child of wandern), target_groups: kinder + familien.
  # Approval kinds in order: professional (1), security (2), editorial (3).
  let(:tour) { events(:section_tour) }
  let(:komitee) { groups(:bluemlisalp_freigabekomitee) }
  let(:base_scope) { Event::Tour.all }

  def filtered(args)
    described_class.new(:approval, args).apply(base_scope)
  end

  def approve_via_komitee(kind, komitee: groups(:bluemlisalp_freigabekomitee))
    tour.approvals.create!(
      approval_kind: event_approval_kinds(kind),
      freigabe_komitee: komitee,
      approved: true,
      creator: people(:admin)
    )
  end

  def approve_directly
    tour.approvals.create!(approved: true, creator: people(:admin))
  end

  context "blank?" do
    it "is blank when no args given" do
      expect(described_class.new(:approval, {})).to be_blank
    end

    it "is not blank when self_approved is '1'" do
      expect(described_class.new(:approval, {self_approved: "1"})).not_to be_blank
    end

    it "is not blank when pending_at_komitee_id is set" do
      expect(described_class.new(:approval, {pending_at_komitee_id: "1"})).not_to be_blank
    end

    it "is not blank when responsible_komitee_id is set" do
      expect(described_class.new(:approval, {responsible_komitee_id: "1"})).not_to be_blank
    end
  end

  context "self_approved filter" do
    subject(:result) { filtered({self_approved: "1"}) }

    context "when not checked" do
      it "passes scope through unchanged" do
        expect(filtered({})).to eq(base_scope)
      end
    end

    context "state filtering" do
      it "excludes tours in review state" do
        expect(result).not_to include(tour)
      end

      it "excludes tours in draft state" do
        tour.update!(state: :draft)
        expect(result).not_to include(tour)
      end

      %w[approved published ready closed canceled].each do |state|
        it "includes tour in #{state} state when no committee approvals exist" do
          tour.update_columns(state: state)
          expect(result).to include(tour)
        end
      end
    end

    context "approval record filtering" do
      before { tour.update_columns(state: :approved) }

      it "includes tour with no approval records at all" do
        expect(result).to include(tour)
      end

      it "includes tour that only has a self approval record" do
        approve_directly
        expect(result).to include(tour)
      end

      it "excludes tour that has a committee approval record" do
        approve_via_komitee(:professional)
        expect(result).not_to include(tour)
      end
    end
  end

  context "pending_at_komitee_id filter" do
    subject(:result) { filtered({pending_at_komitee_id: komitee.id.to_s}) }

    context "when not set" do
      it "passes scope through unchanged" do
        expect(filtered({})).to eq(base_scope)
      end
    end

    it "includes tour in review state when komitee has a pending approval kind" do
      expect(result).to include(tour)
    end

    it "excludes tour not in review state" do
      tour.update_columns(state: :approved)
      expect(result).not_to include(tour)
    end

    it "excludes tour when the selected komitee is not responsible" do
      other_komitee = groups(:bluemlisalp_ortsgruppe_ausserberg_freigabe_komitee)
      expect(filtered({pending_at_komitee_id: other_komitee.id.to_s})).not_to include(tour)
    end

    context "approval kind progression" do
      it "includes tour when first kind is open (none approved yet)" do
        expect(result).to include(tour)
      end

      it "includes tour when first kind is approved and second is open" do
        approve_via_komitee(:professional)
        expect(result).to include(tour)
      end

      it "excludes tour when all approval kinds are approved" do
        approve_via_komitee(:professional)
        approve_via_komitee(:security)
        approve_via_komitee(:editorial)
        expect(result).not_to include(tour)
      end
    end

    it "ignores soft-deleted approval kinds when determining lowest open level" do
      event_approval_kinds(:professional).delete
      # security is now effectively the lowest non-deleted open kind
      expect(result).to include(tour)
    end
  end

  context "responsible_komitee_id filter" do
    subject(:result) { filtered({responsible_komitee_id: komitee.id.to_s}) }

    context "when not set" do
      it "passes scope through unchanged" do
        expect(filtered({})).to eq(base_scope)
      end
    end

    it "includes tour in review state" do
      expect(result).to include(tour)
    end

    it "includes tour in draft state" do
      tour.update!(state: :draft)
      expect(result).to include(tour)
    end

    it "includes tour in approved state" do
      tour.update_columns(state: :approved)
      expect(result).to include(tour)
    end

    it "excludes tour when the selected komitee is not responsible" do
      other_komitee = groups(:bluemlisalp_ortsgruppe_ausserberg_freigabe_komitee)
      expect(filtered({responsible_komitee_id: other_komitee.id.to_s})).not_to include(tour)
    end

    it "excludes tour whose discipline has no responsibility for the komitee" do
      unknown_discipline = Fabricate(:event_discipline)
      unmatched = Fabricate(:sac_tour,
        groups: [groups(:bluemlisalp)],
        disciplines: [unknown_discipline],
        target_groups: [event_target_groups(:kinder)])

      expect(result).not_to include(unmatched)
    end
  end

  context "combined filters (AND logic)" do
    it "applies self_approved and responsible_komitee_id simultaneously" do
      approve_directly
      tour.update_columns(state: :approved)

      # self_approved: no committee approvals AND responsible_komitee matches
      result = filtered({self_approved: "1", responsible_komitee_id: komitee.id.to_s})
      expect(result).to include(tour)
    end

    it "excludes when self_approved matches but responsible_komitee does not" do
      approve_directly
      tour.update_columns(state: :approved)
      other_komitee = groups(:bluemlisalp_ortsgruppe_ausserberg_freigabe_komitee)
      result = filtered({self_approved: "1", responsible_komitee_id: other_komitee.id.to_s})
      expect(result).not_to include(tour)
    end
  end
end
