# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Events::Courses::InvoicesController < ApplicationController
  def create
    authorize!(:summon, participation)

    if ExternalInvoice::Course.invoice_participation(participation).nil?
      flash[:alert] ||= t("event.participations.invoice_not_created_alert")
    else
      flash[:notice] ||= t("event.participations.invoice_created_notice")
    end

    redirect_to group_event_participation_path(params[:group_id], params[:event_id], params[:id])
  end

  private

  def participation
    @participation ||= Event::Participation.find(params[:id])
  end
end
