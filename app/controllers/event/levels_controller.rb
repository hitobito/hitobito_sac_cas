# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::LevelsController < SimpleCrudController
  self.permitted_attrs = [:label, :code, :difficulty, :description]

  self.sort_mappings = {
    label: "event_level_translations.label"
  }

  def self.model_class
    Event::Level
  end
end
