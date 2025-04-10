# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::EventAbility
  extend ActiveSupport::Concern

  prepended do
    on(Event) do
      permission(:any).may(:manage_attachments).for_participations_full_events
    end

    on(Event::Tour) do
      class_side(:list_available).everybody
    end
  end
end
