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
        SELECT event_question_id AS id
          FROM event_question_translations q
          WHERE q.event_question_id = event_questions.id
          AND q.question = 'Notfallkontakt 1 - Name und Telefonnummer'
      ) AND event_questions.event_id IS NULL
    SQL
  end
end
