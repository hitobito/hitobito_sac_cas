# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class RemoveSacMembershipConfigColumns < ActiveRecord::Migration[6.1]
  def change
    remove_column :sac_membership_configs, :service_fee_article_number, :string, null: false
    remove_column :sac_membership_configs, :balancing_payment_article_number, :string, null: false
  end
end
