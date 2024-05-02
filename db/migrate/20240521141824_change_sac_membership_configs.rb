# frozen_string_literal: true

#  copyright (c) 2024, schweizer alpen-club. this file is part of
#  hitobito_sac_cas and licensed under the affero general public license version 3
#  or later. see the copying file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ChangeSacMembershipConfigs < ActiveRecord::Migration[6.1]

  def change
    add_column :sac_membership_configs, :magazine_postage_abroad_article_number, :string, null: false
    add_column :sac_membership_configs, :section_entry_fee_article_number, :string, null: false
    add_column :sac_membership_configs, :section_fee_article_number, :string, null: false
  end

end
