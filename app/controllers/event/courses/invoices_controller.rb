# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Courses::InvoicesController < ApplicationController
  def create
    authorize!(:summon, participation)

    if create_invoice
      flash[:notice] ||= t("event.participations.invoice_created_notice")
    else
      flash[:alert] ||= t("event.participations.invoice_not_created_alert")
    end

    redirect_to group_event_participation_path(params[:group_id], params[:event_id], params[:id])
  end

  private

  def create_invoice
    if participation.state.in?(%w[canceled absent])
      ExternalInvoice::CourseAnnulation.invoice!(participation)
    else
      ExternalInvoice::CourseParticipation.invoice!(participation)
    end
  end

  def participation
    @participation ||= Event::Participation.find(params[:id])
  end
end
