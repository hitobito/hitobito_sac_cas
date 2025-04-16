# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::AbilityDsl::Constraints
  module Event
    def in_same_layer_group
      layer_ids = event.groups.filter { |group| group.id == group.layer_group_id }.map(&:layer_group_id)
      permission_in_layers?(layer_ids)
    end

    def in_same_layer_group_if_active
      in_same_layer_group && at_least_one_group_not_deleted
    end
  end
end
