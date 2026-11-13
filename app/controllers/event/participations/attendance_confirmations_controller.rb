# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Participations::AttendanceConfirmationsController < ApplicationController
  before_action :authorize_action

  def show
    raise ActiveRecord::RecordNotFound unless participation.attendance_confirmable?

    pdf = Export::Pdf::Participations::AttendanceConfirmation.new(participation)
    send_data pdf.render, type: :pdf, disposition: "attachment", filename: pdf.filename
  end

  private

  def participation
    @participation ||= Event::Participation.where(event_id: params[:event_id]).find(params[:id])
  end

  def authorize_action
    authorize!(:show_details, participation)
  end
end
