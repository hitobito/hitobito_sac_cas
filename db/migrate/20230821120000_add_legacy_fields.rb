# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddLegacyFields < ActiveRecord::Migration[6.1]

  def change
    add_column :groups, :navision_id, :string, index: true
    add_column :people, :navision_id, :string, index: true
  end

end
