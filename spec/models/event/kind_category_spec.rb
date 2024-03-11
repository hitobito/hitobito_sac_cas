# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::KindCategory do
  describe "::validations" do
    it "is not valid unless cost_center and cost_unit are set" do
      model = Fabricate.build(:event_kind_category)
      expect(model).to have(1).errors_on(:cost_center_id)
      expect(model).to have(1).errors_on(:cost_unit_id)
    end

    it "is not if kind with same cost_center and cost_unit exists" do
      model = Fabricate.build(:event_kind_category,
                              cost_center: cost_centers(:course),
                              cost_unit: cost_units(:ski))
      expect(model).to have(1).errors_on(:cost_center_id)
      expect(model).to have(1).errors_on(:cost_unit_id)
    end


    it "is valid if cost_center and cost_unit is present" do
      model = Fabricate.build(:event_kind_category,
                              cost_center: cost_centers(:tour),
                              cost_unit: cost_units(:ski))
      expect(model).to be_valid
    end
  end
end
