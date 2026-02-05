# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::TraitsController < Event::NestableTourEssentialsController
  self.sort_mappings = {
    label: "event_trait_translations.label"
  }

  def show
    redirect_to edit_event_trait_path(entry)
  end

  def self.model_class
    Event::Trait
  end
end
