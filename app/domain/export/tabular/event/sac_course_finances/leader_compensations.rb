# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::Event::SacCourseFinances
  class LeaderCompensations
    def fetch(course_ids)
      CourseCompensationRate
        .with(event_starts:)
        .joins(course_compensation_category: {
          event_kinds: {
            events: [participations: :roles]
          }
        })
        .joins("INNER JOIN event_starts ON event_starts.event_id = events.id")
        .where(course_compensation_categories: {leader_settlement: true, kind: :day})
        .where(events: {id: course_ids})
        .where("(event_starts.date_on >= valid_from) AND " \
          "(valid_to IS NULL OR valid_to >= event_starts.date_on)")
        .where(event_roles: {type: highest_leader_role})
        .group("events.id")
        .sum("#{rate_column} * event_participations.actual_days")
    end

    private

    def event_starts
      Event::Date
        .group("event_id")
        .select("event_id, MIN(DATE(start_at)) AS date_on")
    end

    def highest_leader_role
      Event::Role
        .from("event_roles AS r")
        .where("r.participation_id = event_participations.id")
        .where(r: {type: Event::Course.leader_types.map(&:sti_name)})
        .order(leader_order)
        .select("r.type")
        .limit(1)
    end

    def leader_order
      leader_order = Event::Course.leader_types.map.with_index do |role, i|
        "WHEN r.type = '#{role.sti_name}' THEN #{i}"
      end
      Arel.sql("CASE #{leader_order.join(" ")} END")
    end

    def rate_column
      leader_cases = Event::Course.leader_types.map do |role|
        "WHEN event_roles.type = '#{role.sti_name}' " \
        "THEN course_compensation_rates.rate_#{role.name.demodulize.underscore}"
      end
      "CASE #{leader_cases.join(" ")} ELSE 0 END"
    end
  end
end
