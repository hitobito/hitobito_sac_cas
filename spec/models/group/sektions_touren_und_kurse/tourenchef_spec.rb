# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

shared_examples "Tourenchef" do
  it "declares permissions" do
    expect(role_class.permissions).to contain_exactly(
      :layer_and_below_read,
      :layer_events_full,
      :layer_mitglieder_full,
      :layer_touren_und_kurse_full
    )
  end

  it "has group_and_below_full permission on touren_und_kurse"

  it "has group_and_below_full permission on mitglieder"

  it "has two_factor_authentication_enforced"
end

[
  Group::SektionsTourenUndKurseSommer::Tourenchef,
  Group::SektionsTourenUndKurseWinter::Tourenchef,
  Group::SektionsTourenUndKurseAllgemein::Tourenchef
].each do |role_class|
  describe role_class.to_s do
    it_behaves_like "Tourenchef" do
      let(:role_class) { role_class }
    end
  end
end
