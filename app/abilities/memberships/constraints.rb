# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  module Constraints
    delegate :mitglied_termination_by_section_only?, to: :subject

    def for_self_if_active_member_or_backoffice
      active_member? && (for_self? || if_backoffice?)
    end

    def for_self_when_not_terminated_if_active_member_or_backoffice
      active_member? &&
        (for_self_and_not_terminated? ||
        if_backoffice? ||
        termination_by_section_only_false_and_schreibrecht_and_not_terminated?)
    end

    def for_self_and_not_terminated?
      for_self? && !terminated?
    end

    def termination_by_section_only_false_and_schreibrecht_and_not_terminated?
      !mitglied_termination_by_section_only? && schreibrecht_role? && !terminated?
    end

    def if_backoffice?
      role_type?(*SacCas::SAC_BACKOFFICE_ROLES)
    end

    def for_self?
      subject.person == user_context.user
    end

    def active_member?
      People::SacMembership.new(subject.person).active?
    end

    def terminated?
      subject.person.sac_membership.terminated?
    end

    def schreibrecht_role?
      role_type?(Group::SektionsMitglieder::Schreibrecht)
    end
  end
end
