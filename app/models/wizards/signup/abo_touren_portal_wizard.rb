# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Signup
  class AboTourenPortalWizard < AboBasicLoginWizard
    self.steps = [
      Wizards::Steps::Signup::MainEmailField,
      Wizards::Steps::Signup::AboTourenPortal::PersonFields
    ]

    self.asides = ["aside_abo"]

    RESTRICTED_ROLES = [
      Group::AboTourenPortal::Abonnent.sti_name,
      Group::AboTourenPortal::Neuanmeldung.sti_name
    ].freeze

    def member_or_applied?
      current_user&.roles&.map(&:type)&.any? { |type| RESTRICTED_ROLES.include?(type) }
    end

    def costs = SacCas::ABO_COSTS[:tourenportal]
  end
end
