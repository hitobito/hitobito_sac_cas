# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CleanupTourenUndKurseGroups < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE roles
      SET
        group_id = groups.parent_id,
        type = CASE
          WHEN groups.type = 'Group::SektionsTourenUndKurseSommer'    THEN 'Group::SektionsTourenUndKurse::TourenchefSommer'
          WHEN groups.type = 'Group::SektionsTourenUndKurseWinter'    THEN 'Group::SektionsTourenUndKurse::TourenchefWinter'
          WHEN groups.type = 'Group::SektionsTourenUndKurseAllgemein' THEN 'Group::SektionsTourenUndKurse::Tourenchef'
        END
      FROM groups
      WHERE roles.group_id = groups.id
      AND groups.type IN (
        'Group::SektionsTourenUndKurseSommer',
        'Group::SektionsTourenUndKurseWinter',
        'Group::SektionsTourenUndKurseAllgemein'
      );
    SQL

    # Delete all deprecated tour and course group types
    execute <<-SQL
      DELETE FROM groups
      WHERE type IN (
        'Group::SektionsTourenUndKurseSommer',
        'Group::SektionsTourenUndKurseWinter',
        'Group::SektionsTourenUndKurseAllgemein'
      );
    SQL

    # Set names for all Group::SektionsTourenUndKurse based on sektion language
    execute <<-SQL
      WITH group_languages AS (
        SELECT
          g.id,
          CASE
            WHEN ma.value LIKE '%DE%' THEN 'Touren und Kurse'
            WHEN ma.value LIKE '%EN%' THEN 'Tours and courses'
            WHEN ma.value LIKE '%FR%' THEN 'Randonnées et cours'
            WHEN ma.value LIKE '%IT%' THEN 'Visite e corsi'
            ELSE 'Touren und Kurse'
          END as translated_name
        FROM groups g
        LEFT JOIN mounted_attributes ma ON ma.entry_id = g.layer_group_id AND ma.entry_type = 'Group' AND ma.key = 'language'
        WHERE g.type = 'Group::SektionsTourenUndKurse'
      )
      UPDATE groups
      SET name = group_languages.translated_name
      FROM group_languages
      WHERE groups.id = group_languages.id
    SQL
  end
end
