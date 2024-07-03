# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddClassSizeAndAgeToEventKinds < ActiveRecord::Migration[6.1]
  def change
    add_column :event_kinds, :ideal_class_size, :integer
    add_column :event_kinds, :maximum_class_size, :integer
    add_column :event_kinds, :maximum_age, :integer
  end
end
