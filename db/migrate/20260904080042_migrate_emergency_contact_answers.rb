# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MigrateEmergencyContactAnswers < ActiveRecord::Migration[8.0]
  def up
    migrator = Migrations::EmergencyContactAnswersMigrator.new
    say_with_time("copy emergency contacts from Event::Answer to Person") do
      migrator.copy_answers
    end

    say_with_time("delete legacy emergency contact Event::Answers") do
      migrator.remove_legacy_questions
    end
  end

  def down
  end
end
