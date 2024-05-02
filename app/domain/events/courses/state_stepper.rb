# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Events::Courses::StateStepper

  class_attribute :stepping_definitions

  # key: current state
  # value: possible next steps
  self.stepping_definitions =
    {
      created: [:application_open],
      application_open: [:application_paused, :created, :canceled],
      application_paused: [:application_open],
      application_closed: [:assignment_closed, :canceled],
      assignment_closed: [:ready, :canceled],
      ready: [:closed, :canceled],
      canceled: [:application_open],
      closed: [:ready]
    }

  def initialize(course)
    @course = course
  end

  def available_steps
    stepping_definitions[@course.state.to_sym]
  end

  def step_possible?(state)
    available_steps.any?(state.to_sym)
  end

end
