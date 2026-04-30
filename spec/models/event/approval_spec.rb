# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Approval do
  let(:tour) { events(:section_tour) }
  let(:komitee) { groups(:bluemlisalp_freigabekomitee) }
  let(:approval) do
    tour.approvals.build(freigabe_komitee: komitee, approval_kind: event_approval_kinds(:professional))
  end

  describe "validations" do
    it "is valid with all required attributes" do
      expect(approval).to be_valid
    end

    it "validates uniqueness on event, freigabe_komitee and approval_kind" do
      tour.approvals.create!(freigabe_komitee: komitee, approval_kind: event_approval_kinds(:security))
      approval.approval_kind = event_approval_kinds(:security)

      expect(approval).not_to be_valid
    end

    it "does not validate presence of approval_kind without freigabe_komitee" do
      approval.freigabe_komitee = nil
      approval.approval_kind = nil

      expect(approval).to be_valid
    end

    it "validates presence of approval_kind with freigabe_komitee" do
      approval.approval_kind = nil

      expect(approval).not_to be_valid
      expect(approval.errors.full_messages).to eq ["Freigabe-Stufe muss ausgefüllt werden"]
    end
  end
end
