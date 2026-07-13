# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Events::Filter
  class ApplicationOpen < Base
    self.permitted_args = [:value]

    def apply(scope)
      scope.application_period_open
    end

    def blank?
      args[:value].to_i != 1
    end
  end
end
