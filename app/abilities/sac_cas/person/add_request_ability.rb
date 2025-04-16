# frozen_string_literal: true

#  Copyright (c) 2025 Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Person::AddRequestAbility
  extend ActiveSupport::Concern

  prepended do
    on(Person::AddRequest) do
      permission(:layer_events_full)
        .may(:add_without_request)
        .active_or_deleted_in_same_layer
    end
  end
end
