# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::AbilityDsl::Constraints
  module Event
    def in_same_layer_group
      layer_ids = event.groups.filter_map { |g| g.layer_group_id if g.id == g.layer_group_id }
      permission_in_layers?(layer_ids)
    end

    def in_same_layer_group_if_active
      in_same_layer_group && at_least_one_group_not_deleted
    end
  end
end
