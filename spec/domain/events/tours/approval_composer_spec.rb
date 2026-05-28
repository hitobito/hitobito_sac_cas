# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Tours::ApprovalComposer do
  let(:tour) { events(:section_tour) }
  let(:komitee) { groups(:bluemlisalp_freigabekomitee) }
  let(:composer) { described_class.new(tour, nil) }
  let(:person) { people(:mitglied) }

  before { tour.update!(state: :review) }

  def create_pruefer(approval_kinds:, person:)
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

  describe "#next_relevant_pruefer" do
    it "returns empty when no pruefer roles exist in the komitee" do
      expect(composer.next_relevant_pruefer).to be_empty
    end

    it "returns empty when pruefer has no approval kinds assigned" do
      create_pruefer(approval_kinds: [], person:)
      expect(composer.next_relevant_pruefer).to be_empty
    end

    it "returns empty when pruefer exists but not for the next relevant approval kind" do
      create_pruefer(approval_kinds: [event_approval_kinds(:security)], person:)
      expect(composer.next_relevant_pruefer).to be_empty
    end

    it "returns empty when all approval kinds are approved" do
      approve(:professional)
      approve(:security)
      approve(:editorial)
      expect(composer.next_relevant_pruefer).to be_empty
    end

    it "returns pruefer person when pruefer for next relevant approval kind exists" do
      create_pruefer(approval_kinds: [event_approval_kinds(:professional)], person:)
      expect(composer.next_relevant_pruefer).to match_array [person]
    end

    it "returns both people when multiple pruefer for next relevant approval kind exist" do
      create_pruefer(approval_kinds: [event_approval_kinds(:professional)], person:)
      create_pruefer(approval_kinds: [event_approval_kinds(:professional)], person: people(:admin))
      expect(composer.next_relevant_pruefer).to match_array [person, people(:admin)]
    end

    context "pruefer has multiple approval kinds assigned" do
      before { create_pruefer(approval_kinds: event_approval_kinds(:professional, :security, :editorial), person:) }

      it "returns pruefer person for the next relevant kind" do
        expect(composer.next_relevant_pruefer).to match_array [person]
      end

      it "returns pruefer person after first kind is approved" do
        approve(:professional)
        expect(composer.next_relevant_pruefer).to match_array [person]
      end
    end

    context "with multiple relevant komitees" do
      let!(:second_komitee) do
        Group::FreigabeKomitee.create!(
          name: "Komitee 2",
          parent: groups(:bluemlisalp_touren_und_kurse)
        )
      end

      before do
        event_approval_commission_responsibilities(:bluemlisalp_wandern_familien)
          .update!(freigabe_komitee: second_komitee)
        create_pruefer(approval_kinds: [event_approval_kinds(:professional)], person:)
        Group::FreigabeKomitee::Pruefer.create!(group: second_komitee, person: people(:admin),
          approval_kinds: [event_approval_kinds(:professional)])
      end

      it "returns pruefer for next relevant kind in each komitee" do
        expect(composer.next_relevant_pruefer).to match_array [person, people(:admin)]
      end

      it "returns empty when all komitees approved all approval kinds" do
        approve(:professional)
        approve(:security)
        approve(:editorial)
        approve(:professional, freigabe_komitee: second_komitee)
        approve(:security, freigabe_komitee: second_komitee)
        approve(:editorial, freigabe_komitee: second_komitee)
        expect(composer.next_relevant_pruefer).to be_empty
      end
    end
  end

  describe "#all_pruefers" do
    it "returns empty when no pruefer roles exist" do
      expect(composer.all_pruefers).to be_empty
    end

    it "returns all pruefers across the relevant komitees" do
      create_pruefer(approval_kinds: [event_approval_kinds(:professional)], person:)
      create_pruefer(approval_kinds: [event_approval_kinds(:security)], person: people(:admin))
      expect(composer.all_pruefers).to match_array [person, people(:admin)]
    end

    it "does not return duplicates when a pruefer has multiple kinds" do
      create_pruefer(approval_kinds: event_approval_kinds(:professional, :security), person:)
      expect(composer.all_pruefers).to match_array [person]
    end
  end

  describe "#remaining_pruefers" do
    it "returns empty when no pruefer roles exist" do
      expect(composer.remaining_pruefers).to be_empty
    end

    it "excludes the next relevant pruefer" do
      create_pruefer(approval_kinds: [event_approval_kinds(:professional)], person:)
      create_pruefer(approval_kinds: [event_approval_kinds(:security)], person: people(:admin))
      # next_relevant_pruefer is person (professional is first unapproved kind)
      expect(composer.remaining_pruefers).to match_array [people(:admin)]
    end

    it "returns all pruefers when next_relevant_pruefer is empty" do
      approve(:professional)
      approve(:security)
      approve(:editorial)
      create_pruefer(approval_kinds: [event_approval_kinds(:professional)], person:)
      expect(composer.remaining_pruefers).to match_array [person]
    end
  end
end
