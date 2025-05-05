# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  module Constraints
    delegate :mitglied_termination_by_section_only?, to: :subject

    def for_active_member_if_self_or_backoffice_or_schreibrecht
      return false unless active_member?

      backoffice? || for_self? || schreibrecht_role?
    end

    def backoffice? = user_context.user.backoffice?

    def for_self? = subject.person == user_context.user

    def sac_membership = @sac_membership ||= subject.person.sac_membership

    def active_member? = sac_membership.active?

    def terminated? = sac_membership.terminated?

    def schreibrecht_role?
      user_context.user.roles.any? { |role| role.type == Group::SektionsMitglieder::Schreibrecht.sti_name }
    end
  end
end
