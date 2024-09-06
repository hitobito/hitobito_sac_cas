# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::DataQualityCheckerJob < BaseJob
  def perform
    Person.includes(:roles, :phone_numbers, :data_quality_issues).find_each(batch_size: 100) do |person|
      People::DataQualityChecker.new(person).check_data_quality
    end
  end
end
