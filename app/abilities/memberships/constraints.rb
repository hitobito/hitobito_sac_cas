# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  module Constraints
    def for_self_if_active_member_or_backoffice
      active_member? && (for_self? || backoffice?)
    end

    def backoffice?
      user_context.user.backoffice?
    end

    def for_self?
      subject.person == user_context.user
    end

    def active_member?
      People::SacMembership.new(subject.person).active?
    end
  end
end
