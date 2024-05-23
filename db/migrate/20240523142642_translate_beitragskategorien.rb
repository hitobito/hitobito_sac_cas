# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class TranslateBeitragskategorien < ActiveRecord::Migration[6.1]

  MAPPING = {
    adult: :einzel,
    youth: :jugend,
    family: :familie
  }.freeze

  def up
    MAPPING.each do |en, de|
      Role.where(beitragskategorie: de).update_all(beitragskategorie: en)
    end
  end

  def down
    MAPPING.each do |en, de|
      Role.where(beitragskategorie: en).update_all(beitragskategorie: de)
    end
  end
end
