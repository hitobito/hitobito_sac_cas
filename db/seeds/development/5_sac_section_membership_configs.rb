# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

Group::Sektion.all.find_each do |s|
  SacSectionMembershipConfig.reset_column_information
  SacSectionMembershipConfig.seed_once(:valid_from, :group_id,
    group_id: s.id,
    valid_from: "2024",
    section_fee_adult: 42,
    section_fee_family: 84,
    section_fee_youth: 21,
    section_entry_fee_adult: 10,
    section_entry_fee_family: 20,
    section_entry_fee_youth: 5,
    bulletin_postage_abroad: 13,
    sac_fee_exemption_for_honorary_members: false,
    section_fee_exemption_for_honorary_members: true,
    sac_fee_exemption_for_benefited_members: true,
    section_fee_exemption_for_benefited_members: false,
    reduction_amount: 10,
    reduction_required_membership_years: 50,
    reduction_required_age: 42)
end
