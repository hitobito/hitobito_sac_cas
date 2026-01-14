# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::TechnicalRequirement do
  let(:category) { event_technical_requirements(:wandern) }
  let(:child) { event_technical_requirements(:wandern_t3) }

  it ".list orders entries" do
    expect(category.children.list)
      .to eq(event_technical_requirements(:wandern_t1, :wandern_t2, :wandern_t3,
        :wandern_t4, :wandern_t5, :wandern_t6))
  end

  it ".main only returns parents" do
    expect(described_class.main)
      .to match_array(event_technical_requirements(:klettern, :wandern, :skitouren, :singletrail))
  end

  context "validations" do
    it "require presence of label" do
      entry = described_class.new
      expect(entry).not_to be_valid
      expect(entry.errors[:label]).to eq ["muss ausgefüllt werden"]
      entry.label = "Wintersport"
      entry.description = "Beschreibung"
      expect(entry).to be_valid
    end

    it "prevent children as parents" do
      entry = Fabricate.build(:event_technical_requirement, parent: child)
      expect(entry).not_to be_valid
      expect(entry.errors.details[:parent_id]).to eq [error: :parent_is_not_main]
    end
  end

  context "paranoia" do
    it "hard deletes if no associations exist" do
      expect { event_technical_requirements(:skitouren_as).destroy }
        .to change { described_class.unscoped.count }.by(-1)
        .and change { Event::TechnicalRequirement::Translation.count }.by(-1)
    end

    it "soft deletes if events exist" do
      expect { child.destroy }
        .to change { described_class.unscoped.count }.by(0)
        .and change { Event::TechnicalRequirement::Translation.count }.by(0)
      expect(child.deleted_at).to be_present
      expect(child.translations).to be_present
    end

    it "prevents delete if children exist" do
      expect { category.destroy }.not_to change { described_class.unscoped.count }
      expect(category.errors.details[:base]).to eq [error: :has_children]
      expect(category.deleted_at).to be_nil
    end

    it "soft deletes if children are all deleted" do
      event_technical_requirements(:singletrail).children.update_all(deleted_at: Time.zone.now)
      expect { event_technical_requirements(:singletrail).destroy }
        .not_to change { described_class.unscoped.count }
      expect(event_technical_requirements(:singletrail).deleted_at).to be_present
    end
  end
end
