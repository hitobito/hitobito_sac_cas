# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::AboMagazin
  class PersonFields < Wizards::Steps::Signup::PersonFields
    attribute :company, :boolean, default: false
    attribute :company_name, :string

    validates :first_name, :last_name, presence: true, unless: :company
    validates :gender, :birthday, presence: true, unless: :company

    validates :company_name, presence: true, if: :company

    self.minimum_age = 0
    self.partial = "wizards/steps/signup/abo_magazin/person_fields"

    def initialize(...)
      super

      if current_user
        self.company = current_user.company
        self.company_name = current_user.company_name
      end
    end
  end
end
