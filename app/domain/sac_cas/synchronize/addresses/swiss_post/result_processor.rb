#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Synchronize::Addresses::SwissPost
  module ResultProcessor
    def assign_attributes(person, row)
      super

      person.canton = read_canton(row)
    end

    def read_canton(row)
      row["Canton"].downcase
    end
  end
end
