# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacSectionMembershipConfigsController < CrudController
  include MembershipConfigurable

  self.nesting = Group
  self.permitted_attrs = [:valid_from,
    :section_fee_adult,
    :section_fee_family,
    :section_fee_youth,
    :section_entry_fee_adult,
    :section_entry_fee_family,
    :section_entry_fee_youth,
    :bulletin_postage_abroad,
    :sac_fee_exemption_for_honorary_members,
    :section_fee_exemption_for_honorary_members,
    :sac_fee_exemption_for_benefited_members,
    :section_fee_exemption_for_benefited_members,
    :reduction_amount,
    :reduction_required_membership_years,
    :reduction_required_age]

  private

  def new_entry_values
    {
      valid_from: Time.zone.now.year,
      group: group
    }
  end

  def group
    @group ||= Group.find_by(id: params[:group_id], type: model_class.group_types.map(&:sti_name))
  end

  def group_configs
    model_class.where(group_id: group.id)
  end

  def assert_group_type
    head :not_found unless group
  end
end
