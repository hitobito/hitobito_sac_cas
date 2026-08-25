# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ExternalTraining::QualifierIssueJob < BaseJob
  self.parameters = [:external_training_id]

  def initialize(external_training_id)
    super()
    @external_training_id = external_training_id
  end

  def perform
    training = ExternalTraining.find(@external_training_id)
    ExternalTrainings::Qualifier.new(training.person, training, "participant").issue
  end
end
