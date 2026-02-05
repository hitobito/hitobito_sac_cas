# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddAdditionalTourAttributes < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :summit, :string
    add_column :events, :ascent, :integer
    add_column :events, :descent, :integer
    add_column :events, :internal_comment, :text
    add_column :events, :tourenportal_link, :string
    add_column :events, :subito, :boolean, default: false
  end
end
