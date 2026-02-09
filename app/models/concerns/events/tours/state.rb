# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Tours::State
  extend ActiveSupport::Concern

  include Events::State

  included do # rubocop:todo Metrics/BlockLength
    # key: current state
    # value: array of possible next states
    self.state_transitions = {
      draft: [:review, :approved],
      review: [:draft, approved: {dropdown: false}],
      approved: [:draft, :published, :canceled],
      published: [:draft, :approved, :ready, :canceled],
      ready: [:published, :closed, :canceled],
      closed: [:ready],
      canceled: [:approved, :published, :ready]
    }.freeze
  end
end
