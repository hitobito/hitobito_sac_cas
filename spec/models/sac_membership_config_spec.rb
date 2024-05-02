# frozen_string_literal: true
#
#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# == Schema Information
#
# Table name: sac_membership_configs
#
#  id                                             :bigint           not null, primary key
#  valid_from                                     :integer          not null
#  sac_fee_adult                                  :decimal(5, 2)    not null
#  sac_fee_family                                 :decimal(5, 2)    not null
#  sac_fee_youth                                  :decimal(5, 2)    not null
#  entry_fee_adult                                :decimal(5, 2)    not null
#  entry_fee_family                               :decimal(5, 2)    not null
#  entry_fee_youth                                :decimal(5, 2)    not null
#  hut_solidarity_fee_with_hut_adult              :decimal(5, 2)    not null
#  hut_solidarity_fee_with_hut_family             :decimal(5, 2)    not null
#  hut_solidarity_fee_with_hut_youth              :decimal(5, 2)    not null
#  hut_solidarity_fee_without_hut_adult           :decimal(5, 2)    not null
#  hut_solidarity_fee_without_hut_family          :decimal(5, 2)    not null
#  hut_solidarity_fee_without_hut_youth           :decimal(5, 2)    not null
#  magazine_fee_adult                             :decimal(5, 2)    not null
#  magazine_fee_family                            :decimal(5, 2)    not null
#  magazine_fee_youth                             :decimal(5, 2)    not null
#  service_fee                                    :decimal(5, 2)    not null
#  magazine_postage_abroad                        :decimal(5, 2)    not null
#  reduction_amount                               :decimal(5, 2)    not null
#  reduction_required_membership_years            :integer
#  discount_date_1                                :string(255)
#  discount_percent_1                             :integer
#  discount_date_2                                :string(255)
#  discount_percent_2                             :integer
#  discount_date_3                                :string(255)
#  discount_percent_3                             :integer
#  sac_fee_article_number                         :string(255)      not null
#  sac_entry_fee_article_number                   :string(255)      not null
#  hut_solidarity_fee_article_number              :string(255)      not null
#  magazine_fee_article_number                    :string(255)      not null
#  section_bulletin_postage_abroad_article_number :string(255)      not null
#  service_fee_article_number                     :string(255)      not null
#  balancing_payment_article_number               :string(255)      not null
#  course_fee_article_number                      :string(255)      not null
#

require 'spec_helper'

describe SacMembershipConfig do

  let(:config) { sac_membership_configs(:'2024') }

  it 'validates special discount date format' do
    config.discount_date_1 = '1.1'
    config.discount_date_2 = '10'
    config.discount_date_3 = '10.9.'

    expect(config).not_to be_valid

    error_keys = config.errors.attribute_names
    expect(error_keys.count).to eq(2)
    expect(error_keys).to include(:discount_date_1)
    expect(error_keys).to include(:discount_date_2)
    expect(error_keys).not_to include(:discount_date_3)
  end

end
