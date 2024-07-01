# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class AddRemarksToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :sac_remark_national_office, :string, limit: 255
    add_column :people, :sac_remark_section_1, :string, limit: 255
    add_column :people, :sac_remark_section_2, :string, limit: 255
    add_column :people, :sac_remark_section_3, :string, limit: 255
    add_column :people, :sac_remark_section_4, :string, limit: 255
    add_column :people, :sac_remark_section_5, :string, limit: 255
  end
end
