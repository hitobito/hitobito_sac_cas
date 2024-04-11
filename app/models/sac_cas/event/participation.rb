# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::Event::Participation
  extend ActiveSupport::Concern

  prepended do
    before_save :update_previous_state, if: :state_changed?
  end

  private

  def update_previous_state
    if %w(canceled annulled).include?(state)
      self.previous_state = state_was
    end
  end
end

