# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipationBanner
  extend ActiveSupport::Concern

  private

  def action_button_cancel_participation
    action_button(
      t("event.participations.cancel_application.caption"),
      nil,
      "times-circle",
      data: {bs_toggle: "popover", bs_content: render_cancel_popover, bs_placement: :bottom},
      class: "ms-2",
      in_button_group: true
    )
  end

  def can_destroy?
    return super if stateless?

    can?(:cancel, @user_participation) && @user_participation.participant_cancelable? &&
      Event::ParticipationButtons.conditions[:cancel].include?(@user_participation.state.to_sym)
  end

  def render_cancel_popover
    @context.render("event/participations/popover_participant_cancels",
      entry: @user_participation).to_s
  end

  def status_text
    return super if stateless?

    t(@user_participation.state, scope: "event.participations.states")
  end

  def status_class
    return super if stateless?

    alert_class = {
      assigned: :success,
      attended: :success,
      summoned: :success,
      unconfirmed: :warning,
      applied: :warning,
      absent: :warning,
      annulled: :danger,
      canceled: :danger,
      rejected: :danger
    }[@user_participation.state.to_sym]

    "alert alert-#{alert_class}"
  end

  def stateless? = @user_participation.state.blank?
end
