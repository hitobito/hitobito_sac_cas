# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Migrations
  class RoundExternalTrainingDays
    def migrate
      training_ids_per_person = fetch_training_ids_to_reissue_qualifications_per_person
      affected_trainings.update_all("training_days = CEIL(training_days * 2) / 2")

      training_ids_per_person.each do |training_ids|
        # if the current version is not yet deployed to production,
        # inline the job here and run it synchronously.
        # it will take about 20 minutes
        ExternalTraining::QualifierIssueJob.new(training_ids).enqueue!
      end
    end

    def list_affected_people
      CSV.generate do |csv|
        csv << ["Mitgliedernummer"]
        affected_people_ids.each { |id| csv << [id] }
      end
    end

    def list_active_qualifications
      CSV.generate do |csv|
        csv << ["Mitgliedernummer", "Qualifikationsart", "Ablaufdatum"]
        active_qualifications.each do |q|
          csv << [q.person_id, q.qualification_kind.label, q.finish_at]
        end
      end
    end

    private

    def fetch_training_ids_to_reissue_qualifications_per_person
      # DISTINCT ON, ordered by finish_at, picks the earliest adjusted training per
      # person and event_kind (see Memberships::UndoTermination for the same idiom).
      affected_trainings
        .order(:person_id, :event_kind_id, :finish_at)
        .select("DISTINCT ON (person_id, event_kind_id) *")
        .to_a
        .group_by(&:person_id)
        .values
        .map { |trainings| trainings.pluck(:id) }
    end

    def affected_people_ids
      affected_trainings
        .distinct
        .order(:person_id)
        .pluck(:person_id)
    end

    def active_qualifications
      Qualification
        .active
        .includes(:person, qualification_kind: :translations)
        .order(:person_id)
        .order_by_date
        .group_by { |q| [q.person_id, q.qualification_kind_id] }
        .values
        .map(&:first)
    end

    def affected_trainings
      ExternalTraining.where("(training_days * 2) % 1 <> 0")
    end
  end
end
