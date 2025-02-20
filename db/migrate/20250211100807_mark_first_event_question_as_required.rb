# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MarkFirstEventQuestionAsRequired < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      UPDATE event_questions
      SET disclosure = 'required'
      WHERE id IN (
        SELECT event_question_id
        FROM event_question_translations
        WHERE question = 'Notfallkontakt 1 - Name und Telefonnummer'
      );
    SQL
  end
end
