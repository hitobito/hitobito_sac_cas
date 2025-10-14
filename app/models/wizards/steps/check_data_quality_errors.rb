# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Wizards::Steps::CheckDataQualityErrors < Wizards::Step
  delegate :person, to: :wizard
  validate :check_data_quality_errors

  private

  def check_data_quality_errors
    # rubocop:todo Layout/LineLength
    return unless person.data_quality_error? || person.household_people.exists?(data_quality: :error)
    # rubocop:enable Layout/LineLength

    errors.add(:base, :data_quality_error)
  end
end
