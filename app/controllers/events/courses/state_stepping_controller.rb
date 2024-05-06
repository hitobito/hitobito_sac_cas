# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Events::Courses::StateSteppingController < ApplicationController

  @@helper = Object.new
                   .extend(ActionView::Helpers::TranslationHelper)
                   .extend(ActionView::Helpers::OutputSafetyHelper)

  def update
    authorize!(:update, entry)

    save_next_step if step_possible?

    redirect_to group_event_path
  end

  def save_next_step
    entry.state = next_step

    if entry.save
      set_success_notice
    else
      set_failure_notice
    end
  end

  def set_success_notice
    flash.now[:notice] = t('events/courses/state_stepping.flash.success',
                           state: entry.decorate.state_translated)
  end

  def set_failure_notice
    flash[:alert] ||= error_messages.presence
  end

  def error_messages
    @@helper.safe_join(entry.errors.full_messages, '<br/>'.html_safe)
  end

  def next_step
    params[:state]
  end

  def step_possible?
    stepper.step_possible?(next_step)
  end

  def stepper
    @stepper ||= Events::Courses::StateStepper.new(entry)
  end

  def entry
    @entry ||= Event::Course.find(params[:id])
  end

end
