# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth

module SacCas::Event::ParticipationButtons
  extend ActiveSupport::Concern

  prepended do
    self.conditions = {
      cancel: [:unconfirmed, :applied, :assigned, :summoned, if: -> { cancelable? }],
      reject: [:unconfirmed, :applied],
      summon: [:assigned, if: -> { @event.state == 'ready' }],
      absent: [:assigned, :summoned, :attended],
      attend: [:absent, if: -> { @event.closed? }],
      assign: [:unconfirmed, :applied, :absent, if: -> { !@event.closed? }]
    }
  end

  private

  def cancelable?
    return can?(:cancel, @participation) unless her_own?

    can?(:cancel, @participation) && @participation.participant_cancelable?
  end

  def her_own?
    @template.current_user.id == @participation.person_id
  end
end
