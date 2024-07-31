# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::AboBasicLogin
  class PersonFields < Wizards::Steps::Signup::PersonFields
    include Wizards::Steps::Signup::AgreementFields

    NON_ASSIGNABLE_ATTRS = Wizards::Steps::Signup::AgreementFields::AGREEMENTS + [:newsletter]
    self.partial = "wizards/steps/signup/person_fields"

    def requires_adult_consent? = false

    def person_attributes
      super.except(*NON_ASSIGNABLE_ATTRS)
    end
  end
end
