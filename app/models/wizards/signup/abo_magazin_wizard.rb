# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Signup
  class AboMagazinWizard < AboBasicLoginWizard
    self.steps = [
      Wizards::Steps::Signup::MainEmailField,
      Wizards::Steps::Signup::AboMagazin::PersonFields,
      Wizards::Steps::Signup::AboMagazin::IssuesFromField
    ]

    def costs = [
      OpenStruct.new(amount: 60, country: :switzerland),
      OpenStruct.new(amount: 76, country: :international)
    ]

    delegate :newsletter, to: :issues_from_field

    def requires_policy_acceptance? = false
  end
end