# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Group do
  include_examples "group types"

  describe "#id_padded" do
    it "pads the id to 8 characters" do
      group = Group.new(id: 123)
      expect(group.id_padded).to eq("00000123")
    end

    it "returns nil if id is nil" do
      group = Group.new(id: nil)
      expect(group.id_padded).to be_nil
    end
  end
end
