#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class RemoveSelfEmployedFromEventRole < ActiveRecord::Migration[8.0]
  ROLE_TO_GROUP_MAPPING = {
    "Event::Course::Role::Leader" => {
      true  => "KursleitungSelbstaendig",
      false => "KursleitungUnselbstaendig"
    },
    "Event::Course::Role::LeaderAspirant" => {
      true  => "KursleitungAspirantSelbstaendig",
      false => "KursleitungAspirantUnselbstaendig"
    },
    "Event::Course::Role::AssistantLeader" => {
      true  => "KlassenlehrerSelbstaendig",
      false => "KlassenlehrerUnselbstaendig"
    },
    "Event::Course::Role::AssistantLeaderAspirant" => {
      true  => "KlassenlehrerAspirantSelbstaendig",
      false => "KlassenlehrerAspirantUnselbstaendig"
    }
  }.freeze

  def up
    # End all roles in SacCasKurskader by yesterday
    execute <<~SQL
      UPDATE roles
      SET end_on = '2025-08-31'
      WHERE group_id = (SELECT id FROM groups WHERE type = 'Group::SacCasKurskader' LIMIT 1)
      AND (end_on IS NULL OR end_on > '2025-08-31')
    SQL

    # Update types of SacCasKurskader roles
    execute <<~SQL
      UPDATE roles SET type = 'Group::SacCasKurskader::KursleitungSelbstaendig' WHERE type = 'Group::SacCasKurskader::Kursleiter';
      UPDATE roles SET type = 'Group::SacCasKurskader::KlassenlehrerSelbstaendig' WHERE type = 'Group::SacCasKurskader::Klassenlehrer';
      UPDATE roles SET type = 'Group::SacCasKurskader::KursleitungAspirantSelbstaendig' WHERE type = 'Group::SacCasKurskader::KursleiterAspirant';
      UPDATE roles SET type = 'Group::SacCasKurskader::KlassenlehrerAspirantSelbstaendig' WHERE type = 'Group::SacCasKurskader::KlassenlehrerAspirant';
    SQL

    # Create Kurskader roles for event_roles
    new_group_roles = []
    kurskader_group = Group.find_by(type: "Group::SacCasKurskader")

    relevant_event_roles = fetch_relevant_roles.sort_by { _1.participation.event.dates.map(&:start_at).min }

    relevant_event_roles.group_by { _1.participation.participant_id }.each do |person_id, person_roles|
      new_group_roles.concat(
        build_role_attributes_for_person(person_id, person_roles, kurskader_group)
      )
    end

    Role.insert_all(new_group_roles) if new_group_roles.any?

    # Update roles for some selected non self employed people to self employed roles
    execute <<~SQL
      UPDATE roles
      SET type = CASE
        WHEN type = 'Group::SacCasKurskader::KursleitungUnselbstaendig' THEN 'Group::SacCasKurskader::KursleitungSelbstaendig'
        WHEN type = 'Group::SacCasKurskader::KursleitungAspirantUnselbstaendig' THEN 'Group::SacCasKurskader::KursleitungAspirantSelbstaendig'
        WHEN type = 'Group::SacCasKurskader::KlassenlehrerUnselbstaendig' THEN 'Group::SacCasKurskader::KlassenlehrerSelbstaendig'
        WHEN type = 'Group::SacCasKurskader::KlassenlehrerAspirantUnselbstaendig' THEN 'Group::SacCasKurskader::KlassenlehrerAspirantSelbstaendig'
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
        'Group::SacCasKurskader::KlassenlehrerUnselbstaendig',
        'Group::SacCasKurskader::KlassenlehrerAspirantUnselbstaendig'
      )
    SQL

    # Remove self_employed from event_roles
    remove_column :event_roles, :self_employed
  end

  def down
    add_column :event_roles, :self_employed, :boolean, default: false
  end

  private

  def fetch_relevant_roles
    Event::Role.joins(participation: :event)
              .where("events.number LIKE '2026-%'")
              .where(type: ROLE_TO_GROUP_MAPPING.keys)
              .includes(participation: { event: :dates })
  end

  def build_role_attributes_for_person(person_id, person_roles, target_group)
    role_attributes = []

    current_role_type = person_roles.first.type
    current_self_employed = person_roles.first.self_employed
    current_start_date = Date.new(2025, 9, 1)

    person_roles.select do |role|
      role.participation.event.dates.map(&:start_at).min.to_date <= Time.zone.today
    end.each do |role|
      event_date = role.participation.event.dates.map(&:start_at).min.to_date

      if role.self_employed != current_self_employed || role.type != current_role_type
        role_attributes << build_role_attributes(
          target_group, current_role_type, current_self_employed, person_id, current_start_date, (event_date - 1.day)
        )

        current_start_date = event_date
        current_role_type = role.type
        current_self_employed = role.self_employed
      end
    end

    role_attributes << build_role_attributes(
      target_group, current_role_type, current_self_employed, person_id, current_start_date
    )

    role_attributes
  end

  def build_role_attributes(target_group, base_role_type, self_employed, person_id, start_on, end_on = nil)
    {
      type: "Group::SacCasKurskader::#{ROLE_TO_GROUP_MAPPING[base_role_type][self_employed]}",
      group_id: target_group.id,
      person_id: person_id,
      start_on: start_on,
      end_on: end_on
    }
  end
end
