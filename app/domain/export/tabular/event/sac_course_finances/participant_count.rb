# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::Event::SacCourseFinances
  class ParticipantCount
    class_attribute :grouping, :states
    self.states = %w[attended]

    def fetch(course_ids)
      transform_hash(fetch_counts(course_ids))
    end

    private

    def fetch_counts(course_ids)
      participant_scope(course_ids)
        .group(:event_id, grouping)
        .count
    end

    def transform_hash(counts)
      counts.each_with_object({}) do |((event_id, group), count), h|
        h[event_id] ||= Hash.new(0)
        h[event_id][group.respond_to?(:to_sym) ? group.to_sym : group] = count
      end
    end

    def participant_scope(course_ids)
      Event::Participation
        .joins(:roles)
        .where(event_roles: {type: Event::Course::Role::Participant.sti_name})
        .where(event_id: course_ids, state: states)
    end
  end
end
