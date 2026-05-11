# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::StateController < ApplicationController
  def update
    authorize!(:update, entry)

    return head :unprocessable_content unless valid_receiver_options?

    save_next_state if state_possible?

    redirect_to group_event_path
  end

  private

  def save_next_state
    entry.state = next_state

    set_course_attrs if entry.course?
    set_tour_attrs if entry.tour?

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

  def set_tour_attrs
    handle_tour_email_state_change(next_state&.to_sym)
    handle_tour_state_transitions(next_state&.to_sym)
  end

  def handle_tour_email_state_change(next_state)
    return unless tour_email_state_change?(next_state)

    entry.receiver_options = receiver_options
  end

  def handle_tour_state_transitions(next_state)
    assign_internal_comment if tour_email_state_change?(next_state)

    case next_state
    when :approved then build_self_approval
    when :review then rebuild_approvals
    when :canceled then assign_canceled_reason
    end
  end

  def set_success_notice
    flash.now[:notice] = t("events/state.flash.success", state: entry.decorate.state_translated)
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

  def receiver_options
    params[:receiver_options]
  end

  def valid_receiver_options?
    return true if receiver_options.nil? || receiver_options.include?("none")

    receiver_options.all? { Event::Tour::RECEIVER_JOB_MAP.key?(_1) }
  end

  def state_possible?
    entry.state_possible?(next_state)
  end

  def reset_canceled_reason
    entry.canceled_reason = nil
  end

  def build_self_approval
    return unless entry.state_comes_before?(entry.state_was, :approved)

    entry.approvals.each(&:mark_for_destruction)
    entry.approvals.build(approved: true)
  end

  def rebuild_approvals
    if params[:button] == "destroy"
      entry.approvals.each(&:mark_for_destruction)
    elsif params[:button] == "keep"
      Event::Tour::ApprovalForm.new(entry, current_user).reset_approvals
    end
  end

  def assign_canceled_reason
    entry.canceled_reason = params.dig(:event, :canceled_reason)
  end

  def assign_internal_comment
    entry.internal_comment = params.dig(:event, :internal_comment)
  end

  def tour_email_state_change?(next_state)
    [:approved, :published, :canceled, :ready, :closed, :draft].include?(next_state)
  end

  def entry
    @entry ||= Event.find(params[:id])
  end
end
