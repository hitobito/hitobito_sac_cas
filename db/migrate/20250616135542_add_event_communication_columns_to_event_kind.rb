# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddEventCommunicationColumnsToEventKind < ActiveRecord::Migration[7.0]
  def change
    add_column :event_kind_translations, :brief_description, :text
    add_column :event_kind_translations, :specialities, :text
    add_column :event_kind_translations, :similar_tours, :text
    add_column :event_kind_translations, :program, :text
    add_column :event_kind_translations, :seo_text, :text
  end
end
