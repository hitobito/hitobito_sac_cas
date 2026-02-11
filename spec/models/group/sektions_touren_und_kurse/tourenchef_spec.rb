# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

shared_examples "Tourenchef" do
  let(:person) { Fabricate(:person) }
  let(:touren_und_kurse_group) { groups(:bluemlisalp_touren_und_kurse) }

  before do
    group_class = role_class.module_parent
    group = Fabricate(group_class.sti_name.to_sym, parent: touren_und_kurse_group)
    Fabricate(role_class.sti_name.to_sym, person: person, group:)
  end

  def group_and_below_full_groups
    AbilityDsl::UserContext.new(person).permission_group_ids(:group_and_below_full)
  end

  it "declares permissions" do
    expect(role_class.permissions).to include(
      :layer_and_below_read,
      :layer_events_full
    )
  end

  it "has group_and_below_full permission on touren_und_kurse" do
    expect(group_and_below_full_groups).to include(touren_und_kurse_group.id)
  end

  it "does not have group_and_below_full permission on other layers touren_und_kurse" do
    expect(group_and_below_full_groups)
      .not_to include(groups(:bluemlisalp_ortsgruppe_ausserberg_touren_und_kurse).id)
  end

  it "has group_and_below_full permission on mitglieder" do
    expect(group_and_below_full_groups).to include(groups(:bluemlisalp_mitglieder).id)
  end

  it "does not have group_and_below_full permission on other layers mitglieder" do
    expect(group_and_below_full_groups)
      .not_to include(groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder).id)
  end

  it "has two_factor_authentication_enforced" do
    expect(role_class).to be_two_factor_authentication_enforced
  end
end

[
  Group::SektionsTourenUndKurse::TourenchefSommer,
  Group::SektionsTourenUndKurse::TourenchefWinter,
  Group::SektionsTourenUndKurse::Tourenchef
].each do |role_class|
  describe role_class.to_s do
    it_behaves_like "Tourenchef" do
      let(:role_class) { role_class }
    end
  end
end
