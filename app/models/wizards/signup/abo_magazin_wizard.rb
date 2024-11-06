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
      Wizards::Steps::Signup::AboMagazin::Summary
    ]

    self.asides = ["aside_abo"]

    delegate :newsletter, to: :summary

    def costs = SacCas::ABO_COSTS[:magazin]

    def requires_policy_acceptance? = false

    def calculated_costs
      case step("person_fields").country
      when "CH"
        costs.find { |cost| cost.country == :switzerland }.amount
      else
        costs.find { |cost| cost.country == :international }.amount
      end
    end

    def enqueue_notification_email
      Signup::AboMagazinMailer
        .confirmation(person, group, newsletter)
        .deliver_later
    end
  end
end
