# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Roles::EntryHelper do
  subject { Class.new { include SacImports::Roles::EntryHelper }.new }

  describe "#skip" do
    it "sets skipped to true and returns a message" do
      expect(subject.skip("message")).to eq("Skipping: message")
      expect(subject.instance_variable_get(:@skipped)).to be_truthy
    end
  end
end
