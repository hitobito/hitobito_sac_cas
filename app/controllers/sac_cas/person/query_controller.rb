# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Person::QueryController
  extend ActiveSupport::Concern

  prepended do
    self.limit = 20
    self.search_columns += [:birthday, :id]
    self.search_columns -= [:nickname]
  end
end
