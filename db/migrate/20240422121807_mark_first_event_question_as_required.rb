# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MarkFirstEventQuestionAsRequired < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      UPDATE event_questions
      JOIN event_question_translations q on q.event_question_id = event_questions.id
      SET required = true
      WHERE q.question = 'Notfallkontakt 1 - Name und Telefonnummer'
      AND event_questions.event_id IS NULL
    SQL
  end
end
