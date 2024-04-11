# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationsController
  extend ActiveSupport::Concern

  prepended do
    define_model_callbacks :summon
    before_cancel :assert_participant_cancelable?
  end

  def cancel
    entry.cancel_statement = params.dig(:event_participation, :cancel_statement)
    entry.canceled_at = params.dig(:event_participation, :canceled_at) || Time.zone.today
    entry.canceled_at = Time.zone.today if participant_cancels?
    change_state('canceled', 'cancel')
  end

  def summon
    change_state('summoned', 'summon')
  end

  private

  def assert_participant_cancelable?
    if participant_cancels? && !entry.particpant_cancelable?
      entry.errors.add(:base, :invalid)
      throw :abort
    end
  end

  def participant_cancels?
    entry.person == current_user
  end
end
