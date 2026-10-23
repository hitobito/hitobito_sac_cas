# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::QuestionTemplateAbility
  extend ActiveSupport::Concern

  prepended do
    on(::Event::QuestionTemplate) do
      permission(:layer_events_full).may(:manage).in_same_layer
    end
  end
end
