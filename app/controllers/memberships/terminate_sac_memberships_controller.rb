# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class TerminateSacMembershipsController < TerminationController
    private

    def model_params
      params
        .require(:memberships_terminate_sac_membership_form)
        .permit(
          :terminate_on,
          :subscribe_newsletter,
          :subscribe_fundraising_list,
          :data_retention_consent,
          :inform_mitglied_via_email,
          :entry_fee_consent,
          :termination_reason_id
        )
    end

    def role
      @role ||= person.sac_membership.stammsektion_role
    end
  end
end
