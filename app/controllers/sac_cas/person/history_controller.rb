# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Person::HistoryController
  extend ActiveSupport::Concern

  def index
    @external_trainings = ExternalTraining.where(person_id: @person.id)
                                          .includes(event_kind: :translations)
                                          .list
    super
  end

  private

  def roles_scope
    super.with_membership_years
  end

end
