# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::Neuanmeldungen::Promoter
  class NoDuplicateCondition < Condition

    MINIMUM_PERSON_RECORD_AGE = 30.minutes

    def satisfied?
      # The duplicate check makes only sense if the duplicate check has already run after
      # creating the person record. For new people we wait to make sure the duplicate check has run.
      return false if person.created_at > MINIMUM_PERSON_RECORD_AGE.ago

      person.person_duplicates.empty?
    end

  end

end
