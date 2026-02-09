# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::ApprovalKind do
  let(:approval_kind) { event_approval_kinds(:professional) }

  it ".list orders entries" do
    expect(Event::ApprovalKind.list)
      .to eq(event_approval_kinds(:professional, :security, :editorial))
  end

  context "#to_s" do
    it "returns name" do
      expect(approval_kind.to_s).to eq "Fachlich"
    end
  end

  context "validations" do
    it "require presence of name" do
      entry = described_class.new(order: 1)
      expect(entry).not_to be_valid
      expect(entry.errors[:name]).to eq ["muss ausgefüllt werden"]
      entry.name = "Praktisch"
      expect(entry).to be_valid
    end

    it "require presence of order" do
      entry = described_class.new(name: "Praktisch")
      expect(entry).not_to be_valid
      expect(entry.errors[:order]).to eq ["muss ausgefüllt werden"]
      entry.order = 1
      expect(entry).to be_valid
    end

    it "ensures uniqueness of name" do
      entry = described_class.new
      entry.name = "Fachlich"
      expect(entry).not_to be_valid
      expect(entry.errors[:name]).to eq ["ist bereits vergeben"]
    end
  end

  context "paranoia" do
    it "hard deletes if no roles exist" do
      expect { approval_kind.destroy }
        .to change { described_class.unscoped.count }.by(-1)
        .and change { Event::ApprovalKind::Translation.count }.by(-1)
    end

    it "soft deletes if roles exist" do
      approval_kind.roles = [roles(:admin)]
      approval_kind.save!

      expect { approval_kind.destroy }.not_to change { described_class.unscoped.count }
      expect(approval_kind.deleted_at).to be_present
    end
  end
end
