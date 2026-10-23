# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ExternalTraining::QualifierIssueJob < BaseJob
  self.parameters = [:external_training_ids]

  def initialize(external_training_ids)
    super()
    @external_training_ids = external_training_ids
  end

  def perform
    ExternalTraining.where(id: @external_training_ids).order(:finish_at).each do |training|
      Qualification.transaction do
        destroy_later_qualifications(training)
        ExternalTrainings::Qualifier.new(training.person, training).issue
      end
    end
  end

  def destroy_later_qualifications(training)
    quali_kinds = training.kind.qualification_kinds(%w[qualification prolongation], "participant")
    # because of qualifications issued without a qualified_at date before the time of hitobito,
    # we need to check both qualified_at and start_at
    training.person.qualifications
      .where(qualification_kind: quali_kinds)
      .where("qualified_at > :date OR (qualified_at IS NULL AND start_at > :date)",
        date: training.qualification_date)
      .destroy_all
  end
end
