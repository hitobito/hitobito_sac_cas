# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Person::HistoryController

  # We use the same Controller in this wagon also for the memberships tab
  # which checks for the :memberships permission instead of the :history permission.
  # So we catch the CanCan::AccessDenied exception
  def authorize_action
    super
  rescue CanCan::AccessDenied
    authorize!(:memberships, entry)
  end

  def roles_scope
    super.with_membership_years
  end

end
