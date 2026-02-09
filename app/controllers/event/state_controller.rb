# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::StateController < ApplicationController
  def update
    authorize!(:update, entry)

    save_next_state if state_possible?

    redirect_to group_event_path
  end

  private

  def save_next_state
    entry.state = next_state

    set_course_attrs if entry.course?

    if entry.save
      set_success_notice
    else
      set_failure_notice
    end
  end

  def set_course_attrs
    entry.skip_emails = params[:skip_emails]
    if next_state&.to_sym == :canceled
      entry.canceled_reason = params.dig(:event, :canceled_reason)
      entry.inform_participants = params.dig(:event, :inform_participants)
    elsif next_state&.to_sym == :application_open
      reset_canceled_reason
    end
  end

  def set_success_notice
    flash.now[:notice] = t("events/state.flash.success",
      state: entry.decorate.state_translated)
  end

  def set_failure_notice
    flash[:alert] ||= error_messages.presence
  end

  def error_messages
    helpers.safe_join(entry.errors.full_messages, "<br>".html_safe)
  end

  def next_state
    params[:state]
  end

  def state_possible?
    entry.state_possible?(next_state)
  end

  def reset_canceled_reason
    entry.canceled_reason = nil
  end

  def entry
    @entry ||= Event.find(params[:id])
  end
end
