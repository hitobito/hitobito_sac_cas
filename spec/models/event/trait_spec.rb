# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Trait do
  let(:category) { event_traits(:theme) }
  let(:trait) { event_traits(:work) }

  it ".list orders entries" do
    expect(category.children.list)
      .to eq(event_traits(:training, :excursion, :work))
  end

  it ".main only returns parents" do
    expect(described_class.main.list)
      .to eq(event_traits(:organisation, :travel, :theme))
  end

  context "validations" do
    it "require presence of label" do
      entry = described_class.new
      expect(entry).not_to be_valid
      expect(entry.errors[:label]).to eq ["muss ausgefüllt werden"]
      entry.parent = category
      entry.label = "Versammlung"
      expect(entry).to be_valid
    end

    it "prevent children as parents" do
      entry = Fabricate.build(:event_trait, parent: trait)
      expect(entry).not_to be_valid
      expect(entry.errors.details[:parent_id]).to eq [error: :parent_is_not_main]
    end
  end

  context "paranoia" do
    it "hard deletes if no associations exist" do
      expect { trait.destroy }
        .to change { described_class.unscoped.count }.by(-1)
        .and change { Event::Trait::Translation.count }.by(-1)
    end

    it "soft deletes if events exist" do
      trait = events(:section_tour).traits.first
      expect { trait.destroy }
        .to change { described_class.unscoped.count }.by(0)
        .and change { Event::Trait::Translation.count }.by(0)
      expect(trait.deleted_at).to be_present
      expect(trait.translations).to be_present
    end

    it "prevents delete if children exist" do
      expect { category.destroy }.not_to change { described_class.unscoped.count }
      expect(category.errors.details[:base]).to eq [error: :has_children]
      expect(category.deleted_at).to be_nil
    end

    it "soft deletes if children are all deleted" do
      event_traits(:public_transport).update!(deleted_at: Time.zone.now)
      expect { event_traits(:travel).destroy }
        .not_to change { described_class.unscoped.count }
      expect(event_traits(:travel).deleted_at).to be_present
    end
  end
end
