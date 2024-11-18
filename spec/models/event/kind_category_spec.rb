# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::KindCategory do
  describe "::validations" do
    subject(:category) { Fabricate.build(:sac_event_kind_category) }

    it "is valid as builded by fabricator" do
      expect(category).to be_valid
    end

    it "validates presence of cost_center" do
      category.cost_center_id = nil
      expect(category).not_to be_valid
      expect(category.errors[:cost_center]).to eq ["muss ausgefüllt werden"]
    end

    it "validates presence of cost_unit" do
      category.cost_unit_id = nil
      expect(category).not_to be_valid
      expect(category.errors[:cost_unit]).to eq ["muss ausgefüllt werden"]
    end
  end

  describe "#push_down_inherited_attributes" do
    subject(:category) { event_kind_categories(:ski_course) }

    let(:event_kind) { event_kinds(:ski_course) }

    it "overrides cost model on each associated event_kind" do
      event_kind.update!(cost_center: Fabricate(:cost_center), cost_unit: Fabricate(:cost_unit))
      category.push_down_inherited_attributes!
      expect(event_kind.reload.cost_center).to eq category.cost_center
      expect(event_kind.cost_unit).to eq category.cost_unit
    end
  end
end
