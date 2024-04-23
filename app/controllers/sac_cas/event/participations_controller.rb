# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationsController
  extend ActiveSupport::Concern

  WIZARD_STEPS = %w(contact answers subsidy summary).freeze

  prepended do
    define_model_callbacks :summon

    permitted_attrs << :subsidy

    around_create :proceed_wizard
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

  def new
    @step = 'answers' if event.course?
    super
  end

  private

  def proceed_wizard
    @step = params[:step]

    if @step && params[:back]
      previous_step
      render_step
    elsif @step && @step != available_steps.last
      next_step if entry.valid?
      render_step
    else
      yield
    end
  end

  def render_step
    if @step == available_steps.first
      options = {}
      options[:event_role] = { type: params_role_type } if params_role_type
      redirect_to contact_data_group_event_participations_path(group, event, options)
    else
      render :new, status: :unprocessable_entity
    end
    false
  end

  def change_step
    if params[:back]
      previous_step
    else
      next_step
    end
  end

  def next_step
    i = available_steps.index(@step)
    @step = available_steps[i + 1]
  end

  def previous_step
    i = available_steps.index(@step)
    @step = available_steps[i - 1]
  end

  def available_steps
    @available_steps ||= begin
      steps = WIZARD_STEPS
      steps -= ['subsidy'] unless entry.subsidizable?
      steps
    end
  end

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
