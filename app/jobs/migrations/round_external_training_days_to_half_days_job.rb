# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Migrations
  class RoundExternalTrainingDaysToHalfDaysJob < BaseJob
    def perform
      affected_trainings = ExternalTraining.where("(training_days * 2) % 1 <> 0")

      # DISTINCT ON, ordered by finish_at, picks the earliest adjusted training per
      # person and event_kind (see Memberships::UndoTermination for the same idiom).
      training_ids_to_reissue_qualifications = affected_trainings
        .order(:person_id, :event_kind_id, :finish_at)
        .select("DISTINCT ON (person_id, event_kind_id) *")
        .to_a
        .pluck(:id)

      affected_trainings.update_all("training_days = CEIL(training_days * 2) / 2")

      ExternalTraining.where(id: training_ids_to_reissue_qualifications).find_each do |training|
        ExternalTrainings::Qualifier.new(training.person, training, "participant").issue
      end
    end
  end
end
