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
      summon: [:assigned, if: -> { @event.state == "ready" }],
      absent: [:assigned, :summoned, :attended],
      attend: [:absent, if: -> { @event.closed? }],
      assign: [:applied, :absent, if: -> { !@event.closed? }]
    }
  end

  private

  def build_cancel_button
    return super unless her_own?

    popover = render("event/participations/popover_participant_cancels", entry: @participation)
    action_button(t(".cancel_button"),
      nil,
      :"times-circle",
      data: {
        bs_toggle: "popover",
        bs_placement: :bottom,
        bs_content: popover.to_str
      })
  end

  def build_summon_button
    action_button(t(".summon_button"),
      nil,
      :tag,
      onclick: "event.preventDefault();
                $('#summon-confirmation').modal('show');")
  end

  def build_assign_button
    build_action_button(:assign, :tag, data: {confirm: t(".assign_confirm")})
  end

  def cancelable?
    return can?(:cancel, @participation) unless her_own?

    can?(:cancel, @participation) && @participation.participant_cancelable?
  end

  def her_own?
    @template.current_user.id == @participation.person_id
  end
end
