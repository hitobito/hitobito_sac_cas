# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# == Schema Information
#
# Table name: sac_section_membership_configs
#
#  id                                              :bigint           not null, primary key
#  valid_from                                      :integer          not null
#  group_id                                        :bigint
#  section_fee_adult                               :decimal(5, 2)    not null
#  section_fee_family                              :decimal(5, 2)    not null
#  section_fee_youth                               :decimal(5, 2)    not null
#  section_entry_fee_adult                         :decimal(5, 2)    not null
#  section_entry_fee_family                        :decimal(5, 2)    not null
#  section_entry_fee_youth                         :decimal(5, 2)    not null
#  bulletin_postage_abroad                         :decimal(5, 2)    not null
#  sac_fee_exemption_for_honorary_members          :boolean          default(FALSE), not null
#  section_fee_exemption_for_honorary_members      :boolean          default(FALSE), not null
#  sac_fee_exemption_for_benefited_members         :boolean          default(FALSE), not null
#  section_fee_exemption_for_benefited_members     :boolean          default(FALSE), not null
#  reduction_amount                                :decimal(5, 2)    not null
#  reduction_required_membership_years             :integer
#  reduction_required_age                          :integer
#

class SacSectionMembershipConfig < ApplicationRecord

  attr_readonly :valid_from, :group_id

  belongs_to :group

  validates_by_schema
  validates :valid_from, uniqueness: { scope: :group_id }
  validate :assert_sac_section_or_ortsgruppe

  scope :list, -> { order(:valid_from) }

  def self.group_types
    [Group::Sektion, Group::Ortsgruppe]
  end

  def to_s
    valid_from
  end

  private

  def assert_sac_section_or_ortsgruppe
    return if group && self.class.group_types.one? { |t| group.is_a?(t) }

    errors.add(:group, :invalid)
  end
end
