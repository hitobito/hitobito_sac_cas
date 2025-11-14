# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Xlsx::MitgliederStatistics::SectionEintritte do
  let(:group) { groups(:bluemlisalp_mitglieder) }

  let(:range) { Date.new(2024, 1, 1)..Date.new(2024, 12, 31) }
  let(:section) { described_class.new(group, range) }

  let(:reasons) do
    SelfRegistrationReason.all.sort_by(&:text)
  end

  before do
    # reasons are readonly, use workaround to set them
    p1 = create_role(start_on: "2023-12-31").person
    Person.where(id: p1.id).update_all(self_registration_reason_id: reasons.first.id)
    p2 = create_role(start_on: "2024-03-01").person
    Person.where(id: p2.id).update_all(self_registration_reason_id: reasons.second.id)
    p3 = create_role(start_on: "2024-12-31").person
    Person.where(id: p3.id).update_all(self_registration_reason_id: reasons.third.id)
    p4 = create_role(start_on: "2024-04-01").person
    Person.where(id: p4.id).update_all(self_registration_reason_custom_text: "Es gfaut mir so guet")

    Fabricate("Group::SektionsMitglieder::Leserecht", group:, start_on: "2024-06-01") # non-member roles are ignored
  end

  def create_role(**attrs)
    Fabricate(
      "Group::SektionsMitglieder::Mitglied",
      attrs.reverse_merge(group:, beitragskategorie: :adult)
    )
  end

  it "calculates total" do
    expect(section.total).to eq(3)
  end

  it "groups by self registration reasons" do
    expect(section.counts(:self_registration_reason)).to eq(
      reasons.each_with_index.each_with_object({nil => 1}) do |(reason, index), hash|
        hash[reason.text] = index.in?([1, 2]) ? 1 : 0
      end
    )
  end
end
