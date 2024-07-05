# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::TrainingDays::CoursesLoader
  def load
    super + load_external_trainings
  end

  def load_external_trainings
    ExternalTraining.between(@start_date, @end_date)
      .where(person: @person_id)
      .includes(event_kind: {event_kind_qualification_kinds: :qualification_kind})
      .where(event_kind_qualification_kinds: {
        qualification_kind_id: @qualification_kind_ids,
        category: :prolongation,
        role: @role
      })
      .order("start_at DESC")
      .distinct
  end
end
