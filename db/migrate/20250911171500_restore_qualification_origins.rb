# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class RestoreQualificationOrigins < ActiveRecord::Migration[7.1]
  def up
    Qualification.connection.execute(
      <<~SQL
        UPDATE qualifications
        SET origin = external_trainings.name
        FROM external_trainings
        WHERE external_trainings.person_id = qualifications.person_id AND
          external_trainings.finish_at = qualifications.qualified_at AND
          qualifications.origin LIKE '#<data%' AND
          external_trainings.id IS NOT NULL
      SQL
    )
  end

end
