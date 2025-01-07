# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveEnglishLanguage < ActiveRecord::Migration[7.0]
  def change
    connection.execute <<~SQL
      UPDATE people
      SET language = 'de'
      WHERE language = 'en'
    SQL
  end
end
