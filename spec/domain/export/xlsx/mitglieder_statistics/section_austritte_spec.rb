# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Xlsx::MitgliederStatistics::SectionAustritte do
  let(:group) { groups(:bluemlisalp_mitglieder) }

  let(:range) { Date.new(2024, 1, 1)..Date.new(2024, 12, 31) }
  let(:section) { described_class.new(group, range) }

  let(:reasons) do
    TerminationReason.all.sort_by(&:text)
  end

  before do
    create_role(end_on: "2023-12-31", termination_reason: reasons.first)
    create_role(end_on: "2024-03-01", termination_reason: reasons.first)
    create_role(end_on: "2024-12-31", termination_reason: reasons.first)
    create_role(end_on: "2024-04-01")

    # non-member roles are ignored
    Fabricate("Group::SektionsMitglieder::Leserecht",
      group:,
      start_on: "2015-01-01",
      end_on: "2024-06-30")
  end

  def create_role(**attrs)
    Fabricate(
      "Group::SektionsMitglieder::Mitglied",
      attrs.reverse_merge(group:, beitragskategorie: :adult, start_on: "2015-01-01")
    )
  end

  it "calculates total" do
    expect(section.total).to eq(3)
  end

  it "groups by termination reasons" do
    expect(section.counts(:termination_reason)).to eq(
      reasons.each_with_index.each_with_object({nil => 1}) do |(reason, index), hash|
        hash[reason.text] = ((index == 0) ? 2 : 0)
      end
    )
  end
end
