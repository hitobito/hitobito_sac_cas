# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::Event::SacCourseFinances
  class ParticipantCountByAge < ParticipantCount
    AGE_GROUPS = [
      0..17,
      18..22,
      23..35,
      36..50,
      51..60,
      61..
    ].index_with { |range| :"age_#{range.begin}_#{range.end}" }.freeze

    def participant_scope(course_ids)
      super.with_person_participants
    end

    def transform_hash(counts)
      counts.each_with_object({}) do |((event_id, age), count), h|
        range = find_age_group(age)
        next if range.nil?

        h[event_id] ||= Hash.new(0)
        h[event_id][AGE_GROUPS.fetch(range)] += count
      end
    end

    def find_age_group(age)
      AGE_GROUPS.keys.find { |range| range.include?(age) }
    end

    def grouping
      "DATE_PART('YEAR', AGE((#{event_starts.to_sql}), birthday))"
    end

    def event_starts
      Event::Date
        .where("event_id = event_participations.event_id")
        .select("MIN(DATE(start_at))")
    end
  end
end
