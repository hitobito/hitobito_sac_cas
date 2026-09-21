# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Events::Filter::Leader
  extend ActiveSupport::Concern

  included do
    alias_method_chain :apply, :leaders
  end

  def apply_with_leaders(scope)
    scope
      .joins(:cached_leaders)
      .where(event_cached_leaders: {person_id: leader_ids,
                                    role_type: leader_roles.map(&:sti_name)})
  end
end
