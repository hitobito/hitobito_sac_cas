# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Courses::State
  extend ActiveSupport::Concern

  included do
    # key: current state
    # value: possible next state
    SAC_COURSE_STATES =
      { created: [:application_open],
        application_open: [:application_paused, :created, :canceled],
        application_paused: [:application_open],
        application_closed: [:assignment_closed, :canceled],
        assignment_closed: [:ready, :canceled],
        ready: [:closed, :canceled],
        canceled: [:application_open],
        closed: [:ready]
      }.freeze

    self.possible_states = SAC_COURSE_STATES.keys.collect(&:to_s)

    validate :assert_valid_state_change, if: :state_changed?
    before_create :set_default_state
  end

  def available_states(state = self.state)
    SAC_COURSE_STATES[state.to_sym]
  end

  def state_possible?(new_state)
    available_states.any?(new_state.to_sym)
  end

  private

  def assert_valid_state_change
    unless available_states(state_was).include?(state.to_sym)
      errors.add(:state, "State cannot be changed from #{state_was} to #{state}")
    end
  end

  def set_default_state
    self.state = :created
  end
end
