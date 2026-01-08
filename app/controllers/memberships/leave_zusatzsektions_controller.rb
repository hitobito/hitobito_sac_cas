# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class LeaveZusatzsektionsController < TerminationController
    private

    def send_confirmation_mail
      Memberships::TerminateMembershipMailer.leave_zusatzsektion(
        person,
        role.layer_group,
        form_object.terminate_on_date_value,
        form_object.inform_mitglied_via_email
      ).deliver_later
    end

    def role
      @role ||= person.roles.find(params[:role_id])
    end

    def model_params
      params
        .require(:memberships_leave_zusatzsektion_form)
        .permit(:terminate_on, :termination_reason_id)
    end

    def render_abort_views
      return render :open_invoice_exists if !for_someone_else? && open_invoice?
      super
    end
  end
end
