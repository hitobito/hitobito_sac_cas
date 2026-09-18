# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: event_cached_leaders
#
#  id          :bigint           not null, primary key
#  event_id    :integer          not null
#  person_id   :integer          not null
#  role_type   :string           not null
#

class Event::CachedLeader < ActiveRecord::Base
  class << self
    def backfill_all
      backfill_type(Event)
      backfill_type(Event::Course)
      backfill_type(Event::Tour)
    end

    def backfill_event(event)
      backfill_rows(event.class, Event.where(id: event.id))
    end

    private

    def backfill_type(type)
      backfill_rows(type)
    end

    # The rows of every event in events are replaced by those found in leaders. Both scopes are
    # needed: an event that lost its last leader is absent from leaders, but its stale rows still
    # have to go.
    def backfill_rows(type, events = events_scope(type))
      Event.transaction do
        where(event_id: events.select(:id)).delete_all
        fetch_rows(type, events).each_slice(1000) do |slice|
          values = slice.map do |event_id, person_id, role_type|
            {event_id:, person_id:, role_type:}
          end

          insert_all(values)
        end
      end
    end

    def fetch_rows(type, events)
      leaders_scope(type)
        .merge(events)
        .distinct
        .pluck(:event_id, :participant_id, "event_roles.type")
    end

    def events_scope(type)
      Event.where(type: (type == Event) ? ["Event", nil] : type.sti_name)
    end

    def leaders_scope(type)
      events_scope(type)
        .joins(participations: :roles)
        .where(
          event_participations: {active: true, participant_type: "Person"},
          event_roles: {type: type.leader_roles.map(&:sti_name)}
        )
    end
  end

  belongs_to :event
  belongs_to :person

  validates_by_schema
end
