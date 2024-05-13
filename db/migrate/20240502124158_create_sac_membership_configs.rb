# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateSacMembershipConfigs < ActiveRecord::Migration[6.1]

  def change
    create_table :sac_membership_configs do |t|
      t.integer :valid_from, null: false, length: 4, index: { unique: true }

      # fees
      t.decimal :sac_fee_adult, precision: 5, scale: 2, null: false
      t.decimal :sac_fee_family, precision: 5, scale: 2, null: false
      t.decimal :sac_fee_youth, precision: 5, scale: 2, null: false
      t.decimal :entry_fee_adult, precision: 5, scale: 2, null: false
      t.decimal :entry_fee_family, precision: 5, scale: 2, null: false
      t.decimal :entry_fee_youth, precision: 5, scale: 2, null: false
      t.decimal :hut_solidarity_fee_with_hut_adult, precision: 5, scale: 2, null: false
      t.decimal :hut_solidarity_fee_with_hut_family, precision: 5, scale: 2, null: false
      t.decimal :hut_solidarity_fee_with_hut_youth, precision: 5, scale: 2, null: false
      t.decimal :hut_solidarity_fee_without_hut_adult, precision: 5, scale: 2, null: false
      t.decimal :hut_solidarity_fee_without_hut_family, precision: 5, scale: 2, null: false
      t.decimal :hut_solidarity_fee_without_hut_youth, precision: 5, scale: 2, null: false
      t.decimal :magazine_fee_adult, precision: 5, scale: 2, null: false
      t.decimal :magazine_fee_family, precision: 5, scale: 2, null: false
      t.decimal :magazine_fee_youth, precision: 5, scale: 2, null: false
      t.decimal :service_fee, precision: 5, scale: 2, null: false
      t.decimal :magazine_postage_abroad, precision: 5, scale: 2, null: false

      # reductions
      t.decimal :reduction_amount, precision: 5, scale: 2, null: false
      t.integer :reduction_required_membership_years, null: true

      # discounts
      t.string :discount_date_1, null: true
      t.integer :discount_percent_1, null: true, length: 2
      t.string :discount_date_2, null: true
      t.integer :discount_percent_2, null: true, length: 2
      t.string :discount_date_3, null: true
      t.integer :discount_percent_3, null: true, length: 2

      # abacus article numbers
      t.string :sac_fee_article_number, null: false
      t.string :sac_entry_fee_article_number, null: false
      t.string :hut_solidarity_fee_article_number, null: false
      t.string :magazine_fee_article_number, null: false
      t.string :section_bulletin_postage_abroad_article_number, null: false
      t.string :service_fee_article_number, null: false
      t.string :balancing_payment_article_number, null: false
      t.string :course_fee_article_number, null: false
    end
  end

end
