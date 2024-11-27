# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipationConfirmationJob
  extend ActiveSupport::Concern

  delegate :course?, to: "@participation.event"

  private

  def send_confirmation
    course? ? send_confirmation_for_course : super
  end

  def send_confirmation_for_course
    content_key = if participation.state == "assigned"
      Event::ApplicationConfirmationMailer::ASSIGNED
    elsif participation.state == "unconfirmed"
      Event::ApplicationConfirmationMailer::UNCONFIRMED
    else
      Event::ApplicationConfirmationMailer::APPLIED
    end

    Event::ApplicationConfirmationMailer.confirmation(participation, content_key).deliver_later
  end
end
