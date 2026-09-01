# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddShortLabelToEventFitnessRequirements < ActiveRecord::Migration[8.0]
  def change
    add_column :event_fitness_requirement_translations, :short_label, :string, limit: 5

    reversible do |dir|
      dir.up do
        Event::FitnessRequirement.reset_column_information
        I18n.with_locale(:de) do
          Event::FitnessRequirement.find_each do |r|
            r.update!(short_label: r.label[0]) if r.label.present?
          end
        end
      end
    end
  end
end
