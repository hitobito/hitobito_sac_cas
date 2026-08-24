# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

namespace :migrations do
  namespace :round_external_training_days do
    desc "Round ExternalTraining#training_days to half or full days and recalculate " \
      "affected qualifications"
    task migrate: :environment do
      Migrations::RoundExternalTrainingDays.new.migrate
    end

    desc "Export the Mitgliedernummer of people affected by round_external_training_days:migrate"
    task list_affected_people: :environment do
      puts Migrations::RoundExternalTrainingDays.new.list_affected_people
    end
  end
end
