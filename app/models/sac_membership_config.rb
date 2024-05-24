# frozen_string_literal: true
#
#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas
#
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
#  magazine_postage_abroad_article_number         :string(255)      not null
#  section_fee_article_number                     :string(255)      not null
#  section_entry_fee_article_number               :string(255)      not null
#
#

class SacMembershipConfig < ApplicationRecord

  class << self
    def active(date = Time.zone.today)
      where(valid_from: ..date.year).order(valid_from: :desc).first
    end
  end

  attr_readonly :valid_from

  validates_by_schema
  # date format: 1.7., 1.10.
  validates :discount_date_1, :discount_date_2, :discount_date_3,
            format: { with: /\A[0123]?\d\.[012]?\d\.\z/ },
            allow_blank: true
  validates :discount_percent_1, :discount_percent_2, :discount_percent_3,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_blank: true

  scope :list, -> { order(:valid_from) }

  def to_s
    valid_from
  end

  def discount_percent(date)
    index = [3, 2, 1].find do |i|
      discount_date = send("discount_date_#{i}")
      next nil if discount_date.blank?

      Date.parse("#{discount_date}#{date.year}") <= date
    end

    index ? send("discount_percent_#{index}").to_i : 0
  end

end
