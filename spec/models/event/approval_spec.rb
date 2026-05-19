# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Approval do
  let(:tour) { events(:section_tour) }
  let(:komitee) { groups(:bluemlisalp_freigabekomitee) }
  let(:approval_kind) { event_approval_kinds(:security) }
  let(:approval) do
    tour.approvals.build(freigabe_komitee: komitee, approval_kind: event_approval_kinds(:professional))
  end

  describe "validations" do
    it "is valid with all required attributes" do
      expect(approval).to be_valid
    end

    it "validates uniqueness on event, freigabe_komitee and approval_kind" do
      tour.approvals.create!(freigabe_komitee: komitee, approval_kind: approval_kind)
      approval.approval_kind = approval_kind

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

  context "paper trails", versioning: true do
    let(:event) { events(:top_course) }

    it "sets main to event on create" do
      expect do
        tour.approvals.create!(freigabe_komitee: komitee, approval_kind: approval_kind, approved: true)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.where(item_type: Event::Approval.sti_name).order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on update" do
      tour.approvals.create!(freigabe_komitee: komitee, approval_kind: approval_kind, approved: true)

      expect do
        tour.approvals.first.update!(approved: false)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.where(item_type: Event::Approval.sti_name).order(:created_at, :id).last
      expect(version.event).to eq("update")
      expect(version.main).to eq(tour)
    end

    it "does not create version on destroy" do
      tour.approvals.create!(freigabe_komitee: komitee, approval_kind: approval_kind, approved: true)

      expect do
        tour.approvals.first.destroy!
      end.not_to change { PaperTrail::Version.count }
    end
  end
end
