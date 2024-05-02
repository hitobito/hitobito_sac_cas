# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacMembershipConfigsController < CrudController

  include MembershipConfigurable

  self.nesting = Group
  self.permitted_attrs = [:valid_from,
                          :sac_fee_adult,
                          :sac_fee_family,
                          :sac_fee_youth,
                          :entry_fee_adult,
                          :entry_fee_family,
                          :entry_fee_youth,
                          :hut_solidarity_fee_with_hut_adult,
                          :hut_solidarity_fee_with_hut_family,
                          :hut_solidarity_fee_with_hut_youth,
                          :hut_solidarity_fee_without_hut_adult,
                          :hut_solidarity_fee_without_hut_family,
                          :hut_solidarity_fee_without_hut_youth,
                          :magazine_fee_adult,
                          :magazine_fee_family,
                          :magazine_fee_youth,
                          :service_fee,
                          :magazine_postage_abroad,
                          :reduction_amount,
                          :reduction_required_membership_years,
                          :sac_fee_article_number,
                          :sac_entry_fee_article_number,
                          :hut_solidarity_fee_article_number,
                          :magazine_fee_article_number,
                          :section_bulletin_postage_abroad_article_number,
                          :service_fee_article_number,
                          :balancing_payment_article_number,
                          :course_fee_article_number,
                          :discount_date_1,
                          :discount_percent_1,
                          :discount_date_2,
                          :discount_percent_2,
                          :discount_date_3,
                          :discount_percent_3]


  private

  def new_entry_values
    {
      valid_from: Time.zone.now.year,
      discount_date_1: '1.7.',
      discount_date_2: '1.10.'
    }
  end

  def group
    parent
  end

  def assert_group_type
    head :not_found unless group.root?
  end
end
