# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::State
  extend ActiveSupport::Concern

  included do
    # key: current state
    # value: array of possible next states
    class_attribute :state_transitions

    # key: current state
    # value: array of possible next states
    class_attribute :state_transition_emails_skippable, default: {}

    validate :assert_valid_state_change, if: :state_changed?, on: :update

    before_create :set_default_state
  end

  module ClassMethods
    def possible_states
      @possible_states ||= state_transitions.keys.map(&:to_s)
    end
  end

  def manually_configurable_states
    transitions_for_current_state(state).reject {
      _1.is_a?(Hash) && _1.values.any? { |v| v[:dropdown] == false }
    }.flat_map { extract_state_name(_1) }
  end

  def available_states(state = self.state)
    transitions_for_current_state(state).flat_map { extract_state_name(_1) }
  end

  def state_comes_before?(state1, state2)
    states = state_transitions.keys
    states.index(state1.to_sym) < states.index(state2.to_sym)
  end

  def state_possible?(new_state)
    available_states.any?(new_state.to_sym)
  end

  private

  def transitions_for_current_state(state)
    state_transitions[state.to_sym] || []
  end

  def extract_state_name(entry)
    entry.is_a?(Hash) ? entry.keys : entry
  end

  def assert_valid_state_change
    unless available_states(state_was).include?(state.to_sym)
      errors.add(:state, "State cannot be changed from #{state_was} to #{state}")
    end
  end

  def set_default_state
    # rubocop:todo Layout/LineLength
    # Explicitly call self[:state].blank? because self.state is overridden in youth wagon to return first possible state if nil.
    # rubocop:enable Layout/LineLength
    self.state = possible_states.first if self[:state].blank?
  end

  def state_changed_to?(new_state)
    saved_change_to_state?(to: new_state.to_s)
  end
end
