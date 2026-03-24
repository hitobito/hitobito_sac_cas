#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class RemoveSelfEmployedFromEventRole < ActiveRecord::Migration[8.0]
  def up
    # End all roles in SacCasKurskader by yesterday
    execute <<~SQL
      UPDATE roles
      SET end_on = '#{Time.zone.yesterday}'
      WHERE end_on IS NULL
      AND group_id = (SELECT id FROM groups WHERE type = 'Group::SacCasKurskader' LIMIT 1)
    SQL

    # Update types of SacCasKurskader roles
    execute <<~SQL
      UPDATE roles SET type = 'Group::SacCasKurskader::KursleitungSelbstaendig' WHERE type = 'Group::SacCasKurskader::Kursleiter';
      UPDATE roles SET type = 'Group::SacCasKurskader::KlassenleitungSelbstaendig' WHERE type = 'Group::SacCasKurskader::Klassenlehrer';
      UPDATE roles SET type = 'Group::SacCasKurskader::KursleitungAspirantSelbstaendig' WHERE type = 'Group::SacCasKurskader::KursleiterAspirant';
      UPDATE roles SET type = 'Group::SacCasKurskader::KlassenleitungAspirantSelbstaendig' WHERE type = 'Group::SacCasKurskader::KlassenlehrerAspirant';
    SQL

    # Create Kurskader roles for event_roles
    execute <<~SQL
      INSERT INTO roles (person_id, group_id, type, start_on, created_at, updated_at)
      SELECT DISTINCT
        event_participations.participant_id,
        (SELECT id FROM groups WHERE type = 'Group::SacCasKurskader' LIMIT 1),
        CASE
          WHEN event_roles.type = 'Event::Course::Role::Leader' AND event_roles.self_employed = TRUE  THEN 'Group::SacCasKurskader::KursleitungSelbstaendig'
          WHEN event_roles.type = 'Event::Course::Role::Leader' AND event_roles.self_employed = FALSE THEN 'Group::SacCasKurskader::KursleitungUnselbstaendig'
          WHEN event_roles.type = 'Event::Course::Role::LeaderAspirant' AND event_roles.self_employed = TRUE  THEN 'Group::SacCasKurskader::KursleitungAspirantSelbstaendig'
          WHEN event_roles.type = 'Event::Course::Role::LeaderAspirant' AND event_roles.self_employed = FALSE THEN 'Group::SacCasKurskader::KursleitungAspirantUnselbstaendig'
          WHEN event_roles.type = 'Event::Course::Role::AssistantLeader' AND event_roles.self_employed = TRUE  THEN 'Group::SacCasKurskader::KlassenleitungSelbstaendig'
          WHEN event_roles.type = 'Event::Course::Role::AssistantLeader' AND event_roles.self_employed = FALSE THEN 'Group::SacCasKurskader::KlassenleitungUnselbstaendig'
          WHEN event_roles.type = 'Event::Course::Role::AssistantLeaderAspirant' AND event_roles.self_employed = TRUE  THEN 'Group::SacCasKurskader::KlassenleitungAspirantSelbstaendig'
          WHEN event_roles.type = 'Event::Course::Role::AssistantLeaderAspirant' AND event_roles.self_employed = FALSE THEN 'Group::SacCasKurskader::KlassenleitungAspirantUnselbstaendig'
        END,
        NOW(),
        NOW(),
        NOW()
      FROM event_roles
      JOIN event_participations ON event_participations.id = event_roles.participation_id
      JOIN events ON events.id = event_participations.event_id
      WHERE events.number LIKE '2026-%'
      AND event_roles.type IN (
        'Event::Course::Role::Leader',
        'Event::Course::Role::LeaderAspirant',
        'Event::Course::Role::AssistantLeader',
        'Event::Course::Role::AssistantLeaderAspirant'
      )
    SQL

    # Update roles for some selected non self employed people to self employed roles
    execute <<~SQL
      UPDATE roles
      SET type = CASE
        WHEN type = 'Group::SacCasKurskader::KursleitungUnselbstaendig' THEN 'Group::SacCasKurskader::KursleitungSelbstaendig'
        WHEN type = 'Group::SacCasKurskader::KursleitungAspirantUnselbstaendig' THEN 'Group::SacCasKurskader::KursleitungAspirantSelbstaendig'
        WHEN type = 'Group::SacCasKurskader::KlassenleitungUnselbstaendig' THEN 'Group::SacCasKurskader::KlassenleitungSelbstaendig'
        WHEN type = 'Group::SacCasKurskader::KlassenleitungAspirantUnselbstaendig' THEN 'Group::SacCasKurskader::KlassenleitungAspirantSelbstaendig'
      END
      WHERE person_id IN (
        490821, 231663, 385167, 228002, 368341, 437092, 518011, 461133, 404226, 295103,
        352136, 318281, 394993, 327065, 175440, 304162, 494802, 367569, 296018, 378573,
        483461, 305992, 468474, 623261, 200454, 406288, 180566, 441480, 204060, 483541,
        187961, 665146, 410824, 332710,  38892, 351764, 411349, 342810, 356408, 175943,
        426858, 166671, 424946, 513956, 273711, 221870, 371663, 161001, 226810, 232930,
        411410, 284562, 190936, 257747, 227971, 196189,  143059
      )
      AND type IN (
        'Group::SacCasKurskader::KursleitungUnselbstaendig',
        'Group::SacCasKurskader::KursleitungAspirantUnselbstaendig',
        'Group::SacCasKurskader::KlassenleitungUnselbstaendig',
        'Group::SacCasKurskader::KlassenleitungAspirantUnselbstaendig'
      )
    SQL

    # Remove self_employed from event_roles
    remove_column :event_roles, :self_employed
  end

  def down
    add_column :event_roles, :self_employed, :boolean, default: false
  end
end
