# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Events::Filter
  class Sac < Base
    self.permitted_args = [:season, :subito]

    def apply(scope)
      scope = filter_season(scope)
      filter_subito(scope)
    end

    private

    def filter_season(scope)
      return scope if args[:season].blank?

      scope.where(season: args[:season])
    end

    def filter_subito(scope)
      return scope if args[:subito].blank?

      scope.where(subito: args[:subito] == "true")
    end
  end
end
