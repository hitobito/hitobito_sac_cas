#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddMoreTourAttributes < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :duration_h, :integer
    add_column :events, :duration_m, :integer
    add_column :events, :maps, :string

    add_column :event_translations, :alternative_route, :text
    add_column :event_translations, :additional_info, :text
    add_column :event_translations, :price_description, :text
  end
end
