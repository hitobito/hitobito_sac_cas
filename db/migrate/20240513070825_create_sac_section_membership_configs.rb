# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateSacSectionMembershipConfigs < ActiveRecord::Migration[6.1]

  def change
    create_table :sac_section_membership_configs do |t|
      t.integer :valid_from, null: false, length: 4
      t.references :group, null: false

      # fees
      t.decimal :section_fee_adult, precision: 5, scale: 2, null: false
      t.decimal :section_fee_family, precision: 5, scale: 2, null: false
      t.decimal :section_fee_youth, precision: 5, scale: 2, null: false
      t.decimal :section_entry_fee_adult, precision: 5, scale: 2, null: false
      t.decimal :section_entry_fee_family, precision: 5, scale: 2, null: false
      t.decimal :section_entry_fee_youth, precision: 5, scale: 2, null: false
      t.decimal :bulletin_postage_abroad, precision: 5, scale: 2, null: false

      # reductions
      t.boolean :sac_fee_exemption_for_honorary_members, null: false, default: false
      t.boolean :section_fee_exemption_for_honorary_members, null: false, default: false
      t.boolean :sac_fee_exemption_for_benefited_members, null: false, default: false
      t.boolean :section_fee_exemption_for_benefited_members, null: false, default: false
      t.decimal :reduction_amount, precision: 5, scale: 2, null: false
      t.integer :reduction_required_membership_years, null: true
      t.integer :reduction_required_age, null: true
    end

    add_index :sac_section_membership_configs, [:group_id, :valid_from], unique: true
  end

end
