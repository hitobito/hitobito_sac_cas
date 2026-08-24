# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Migrations
  class RoundExternalTrainingDays
    def migrate
      affected_trainings = ExternalTraining.where("(training_days * 2) % 1 <> 0")

      # DISTINCT ON, ordered by finish_at, picks the earliest adjusted training per
      # person and event_kind (see Memberships::UndoTermination for the same idiom).
      training_ids_to_reissue_qualifications = affected_trainings
        .order(:person_id, :event_kind_id, :finish_at)
        .select("DISTINCT ON (person_id, event_kind_id) *")
        .to_a
        .pluck(:id)

      affected_trainings.update_all("training_days = CEIL(training_days * 2) / 2")

      training_ids_to_reissue_qualifications.each do |id|
        ExternalTraining::QualifierIssueJob.new(id).enqueue!
      end
    end

    def list_affected_people
      person_ids = ExternalTraining.where("(training_days * 2) % 1 <> 0")
        .distinct
        .order(:person_id)
        .pluck(:person_id)

      CSV.generate do |csv|
        csv << ["Mitgliedernummer"]
        person_ids.each { |id| csv << [id] }
      end
    end
  end
end
