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

    # rubocop:todo Layout/LineLength
    def redirection_message = I18n.t("groups.self_registration.create.already_member_of_tourenportal")
    # rubocop:enable Layout/LineLength

    def calculated_costs = Group.root.abo_touren_portal_fee

    def shipping_abroad? = false

    private

    def build_person
      super do |person, role|
        role.end_on = Date.current.end_of_year
      end
    end
  end
end
