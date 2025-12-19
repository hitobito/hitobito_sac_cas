# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Level do
  let(:level) { event_levels(:ek) }

  context "validations" do
    it "require presence of label" do
      entry = described_class.new(code: 2, difficulty: 1)
      expect(entry).not_to be_valid
      expect(entry.errors[:label]).to eq ["muss ausgefüllt werden"]
      entry.label = "Einfach"
      expect(entry).to be_valid
    end
  end

  context "paranoia" do
    it "hard deletes if no associations exist" do
      entry = Event::Level.create!(label: "Einfach", code: 2, difficulty: 1)
      expect { entry.destroy }.to change { described_class.unscoped.count }.by(-1)
    end

    it "soft deletes if kinds exist" do
      expect { level.destroy }.not_to change { described_class.unscoped.count }
      expect(level.deleted_at).to be_present
    end
  end
end
