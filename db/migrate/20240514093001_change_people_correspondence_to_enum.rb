# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ChangePeopleCorrespondenceToEnum < ActiveRecord::Migration[6.1]
  def change
    remove_column :people, :digital_correspondence
    add_column :people, :correspondence, :string, null: false, default: 'digital'
  end
end
