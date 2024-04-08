# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Events::Courses::StateSteppingController < ApplicationController

  def update
    authorize!(:update, entry)

    if step_possible?
      entry.update!(state: next_step)
      set_success_notice
    end

    redirect_to group_event_path
  end

  def set_success_notice
    flash.now[:notice] = t('events/courses/state_stepping.flash.success',
                           state: entry.decorate.state_translated)
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
    Event::Course.find(params[:id])
  end

end
