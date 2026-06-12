# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::Event::SacCourseFinances
  class ParticipantCountByMembership < ParticipantCount
    self.grouping = "is_member"

    def participant_scope(course_ids)
      super.with_person_participants
    end

    def grouping
      "EXISTS(#{membership_roles.to_sql})"
    end

    def membership_roles
      Role
        .unscoped
        .with(event_starts:)
        .where(type: SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name))
        .where("roles.person_id = people.id")
        .joins("INNER JOIN event_starts ON " \
               "(roles.start_on IS NULL OR roles.start_on <= event_starts.date_on) AND " \
               "(roles.end_on IS NULL OR roles.end_on >= event_starts.date_on)")
    end

    def event_starts
      Event::Date
        .where("event_id = event_participations.event_id")
        .select("MIN(DATE(start_at)) AS date_on")
    end
  end
end
