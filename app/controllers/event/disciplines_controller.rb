# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::DisciplinesController < Event::NestableTourEssentialsController
  self.sort_mappings = {
    label: "event_discipline_translations.label"
  }

  self.permitted_attrs += [:color]

  def show
    redirect_to edit_event_discipline_path(entry)
  end

  def self.model_class
    Event::Discipline
  end
end
