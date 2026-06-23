# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::TourReportMailer < ApplicationMailer
  include ::TourMailer

  SUBMITTED = "event_tour_report_submitted"
  REJECTED = "event_tour_report_rejected"
  APPROVED = "event_tour_report_approved"
  PAYOUT_REJECTED = "event_tour_report_payout_rejected"
  PAYOUT_RECORDED = "event_tour_report_payout_recorded"

  def submitted(report, recipients)
    compose_email(report, recipients, SUBMITTED)
  end

  def rejected(report, recipients)
    compose_email(report, recipients, REJECTED)
  end

  def approved(report, recipients)
    compose_email(report, recipients, APPROVED)
  end

  def payout_rejected(report, recipients)
    compose_email(report, recipients, PAYOUT_REJECTED)
  end

  def payout_recorded(report, recipients)
    compose_email(report, recipients, PAYOUT_RECORDED)
  end

  private

  def compose_email(report, recipients, content_key)
    @people = Array(recipients).flatten
    @report = report

    @event = @report.event
    @group = @context = @event.groups.first

    I18n.with_locale(@group.language) do
      compose(@people, content_key, context: @context)
    end
  end

  def placeholder_report_remarks
    @report.remarks
  end
end
