# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddSurveyHeroFieldsToEventKindsAndEvents < ActiveRecord::Migration[8.0]
  def change
    [:event_kinds, :events].each do |table|
      add_column table, :survey_hero_survey_key, :string
      add_column table, :survey_hero_collector_key, :string
    end

    add_column :events, :survey_auto_send, :boolean, default: true, null: false

    Event.reset_column_information
  end
end
