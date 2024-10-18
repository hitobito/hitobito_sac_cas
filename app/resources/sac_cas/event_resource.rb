# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::EventResource
  extend ActiveSupport::Concern

  included do
    filter :level_id, :integer, only: [:eq, :not_eq] do
      eq { |scope, level_ids| scope.select("events.*").joins(:kind).where(kind: {level_id: level_ids}) }
      not_eq { |scope, level_ids| scope.select("events.*").joins(:kind).where.not(kind: {level_id: level_ids}) }
    end
  end
end
