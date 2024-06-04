# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Sheet::Group::NavLeft
  NAME_WITHOUT_PREFIX = "REPLACE(REPLACE(name, 'SAC ', ''), 'CAS ', '')".freeze

  private

  def sub_layers
    super.reorder(Arel.sql(NAME_WITHOUT_PREFIX))
  end
end
