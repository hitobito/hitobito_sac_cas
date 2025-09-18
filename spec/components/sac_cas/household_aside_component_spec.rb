# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe HouseholdAsideComponent, type: :component do
  let(:familienmitglied) { people(:familienmitglied) }
  let(:familienmitglied2) { people(:familienmitglied2) }
  let(:familienmitglied_kind) { people(:familienmitglied_kind) }
  let(:group) { groups(:bluemlisalp) }
  let(:member_component) { HouseholdAsideMemberComponent.new(person: familienmitglied) }

  subject(:component) { described_class.new(person: familienmitglied, group: group) }

  it "returns the humanized name of the Household model" do
    stub_can(:show, true)
    stub_can(:create_households, true)
    stub_can(:update, true)

    rendered_component = render_inline(component)
    expect(rendered_component).to have_selector("h2", text: "Familie")
  end

  private

  def stub_can(permission, result)
    allow(component).to receive(:can?).with(permission, anything).and_return(result)
    allow_any_instance_of(HouseholdAsideMemberComponent).to receive(:can?).with(permission,
      anything).and_return(result)
  end
end
