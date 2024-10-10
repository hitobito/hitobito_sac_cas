# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::Sektion
  class PersonFields < Wizards::Steps::Signup::PersonFields
    self.partial = "wizards/steps/signup/person_fields"

    validate :require_gender
    validates :street, :housenumber, :town, :zip_code,
      :country, :phone_number, presence: true

    def required_attrs
      [:address, :gender]
    end

    private

    def require_gender
      errors.add(:gender, :blank) if attributes["gender"].nil?
    end
  end
end
