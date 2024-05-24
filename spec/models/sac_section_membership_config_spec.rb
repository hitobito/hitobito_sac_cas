# frozen_string_literal: true

# == Schema Information
#
# Table name: sac_section_membership_configs
#
#  id                                              :bigint           not null, primary key
#  valid_from                                      :integer          not null
#  group_id                                        :bigint
#  section_fee_adult                           :decimal(5, 2)    not null
#  section_fee_family                          :decimal(5, 2)    not null
#  section_fee_youth                           :decimal(5, 2)    not null
#  section_entry_fee_adult                                 :decimal(5, 2)    not null
#  section_entry_fee_family                                :decimal(5, 2)    not null
#  section_entry_fee_youth                                 :decimal(5, 2)    not null
#  bulletin_postage_abroad                         :decimal(5, 2)    not null
#  sac_fee_exemption_for_honorary_members          :boolean          default(FALSE), not null
#  section_fee_exemption_for_honorary_members  :boolean          default(FALSE), not null
#  sac_fee_exemption_for_benefited_members         :boolean          default(FALSE), not null
#  section_fee_exemption_for_benefited_members :boolean          default(FALSE), not null
#  reduction_amount                                :decimal(5, 2)    not null
#  reduction_required_membership_years             :integer
#  reduction_required_age                          :integer
#
#
#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SacSectionMembershipConfig do

  let(:config) { sac_section_membership_configs(:bluemlisalp_2024) }

  context 'group' do
    let(:new_config) { config.dup.tap { |c| c.valid_from = 2025 } }

    it 'cannot belong to top layer' do
      new_config.group = groups(:root)

      expect(new_config).not_to be_valid
      error_keys = new_config.errors.attribute_names
      expect(error_keys.count).to eq(1)
      expect(error_keys).to include(:group)
    end

    it 'can belong to sektion' do
      expect(new_config).to be_valid
    end

    it 'can belong to ortsgruppe' do
      new_config.group = groups(:bluemlisalp_ortsgruppe_ausserberg)

      expect(new_config).to be_valid
    end
  end
end
