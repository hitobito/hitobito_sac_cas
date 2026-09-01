# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# The leaders of the given events, loaded for all of them at once so that the
# agenda's list can render them without an N+1.
class AgendaLeaders
  PERSON_ATTRIBUTES = [
    :id,
    :first_name,
    :last_name,
    :nickname,
    :company,
    :company_name,
    :updated_at
  ].freeze

  class << self
    def scope
      Person
        .select(*PERSON_ATTRIBUTES)
        .joins(event_participations: :roles)
        .where(
          event_participations: {active: true},
          event_roles: {type: leader_roles.map(&:sti_name)}
        )
        .order_by_name
        .distinct
    end

    def filter_leaders(group)
      scope
        .joins(event_participations: [event: [:dates, :groups]])
        .where(
          groups: {id: group.id},
          event_dates: {start_at: leader_date_range}
        )
    end

    def leader_roles
      Events::Filter::Leader.new(:leader, {}).leader_roles
    end

    private

    def leader_date_range
      today = Time.zone.today
      Date.new(today.year, 1, 1)..Date.new(today.year + 1, 12, 31)
    end
  end

  def initialize(events)
    @events = Array(events)
  end

  def to_h
    grouped = leaders.group_by { |person| person.event_id }
    @events.to_h { |event| [event.id, sort(grouped[event.id].to_a, event)] }
  end

  private

  def leaders
    return [] if @events.empty?

    self.class.scope
      .select("event_participations.event_id AS event_id",
        "event_roles.type AS role_type")
      .where(event_participations: {event_id: @events.map(&:id)})
  end

  def sort(people, event)
    order = event.class.leader_types.map(&:sti_name)
    people
      .each_with_index
      .sort_by { |person, index| [order.index(person.role_type) || order.size, index] }
      .map(&:first)
      .uniq(&:id)
  end
end
