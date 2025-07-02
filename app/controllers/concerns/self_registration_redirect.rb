# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SelfRegistrationRedirect
  SELFREG_COMPLETED_TARGET_KEY = :selfreg_completed_redirect

  def redirect_to_self_registration(group_id, completion_redirect_target = nil)
    session[SELFREG_COMPLETED_TARGET_KEY] = completion_redirect_target
    redirect_to group_self_registration_path(group_id: group_id)
  end

  def self_registration_completed_redirect_target
    if session[SELFREG_COMPLETED_TARGET_KEY].present?
      session.delete(SELFREG_COMPLETED_TARGET_KEY)
    else
      history_group_person_path(
        group_id: current_user.reload.primary_group_id || Group.root.id,
        id: current_user.id
      )
    end
  end
end
