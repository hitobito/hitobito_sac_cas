# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

xdescribe SacImports::Roles::Nav2b2NonMembershipImporter do
  context "#create_role" do
    it "creates a role"
    it "does not create duplicate roles"
  end

  context "#find" do
    it "finds a group"
    it "does not create group"
  end

  context "#find" do
    it "finds a group"
    it "creates missing group"
    it "does not create duplicate group"
  end

  context "#load_or_create_group" do
    it "works correctly" # TODO: write meaningful tests
  end
end
