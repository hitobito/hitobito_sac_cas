# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationsController
  extend ActiveSupport::Concern

  WIZARD_STEPS = %w[contact answers subsidy summary].freeze

  prepended do
    define_model_callbacks :summon

    permitted_attrs << :subsidy << :adult_consent << :terms_and_conditions << :newsletter

    around_create :proceed_wizard
    after_create :subscribe_newsletter, :send_participation_confirmation_email
    before_cancel :assert_participant_cancelable?
  end

  def cancel
    entry.cancel_statement = params.dig(:event_participation, :cancel_statement)
    entry.canceled_at = params.dig(:event_participation, :canceled_at) || Time.zone.today
    entry.canceled_at = Time.zone.today if participant_cancels?
    change_state("canceled", "cancel")
  end

  def summon
    change_state("summoned", "summon")
  end

  def new
    @step = "answers" if event.course?
    super
  end

  private

  def permitted_attrs
    permitted = self.class.permitted_attrs.dup

    permitted << :actual_days if can?(:edit_actual_days, entry)

    permitted
  end

  def proceed_wizard # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @step = params[:step]
    return yield if @step.blank? || !event.course?

    if params[:back]
      previous_step
      render_step
    elsif @step == available_steps.last
      finish_wizard
      yield
    else
      next_step if entry.valid?
      render_step
    end
  end

  def render_step
    if @step == available_steps.first
      options = {}
      options[:event_role] = {type: params_role_type} if params_role_type
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
      steps -= ["subsidy"] unless entry.subsidizable?
      steps
    end
  end

  def finish_wizard
    entry.check_root_conditions! if group.root?
  end

  def subscribe_newsletter
    return if !subscribe_newsletter? || entry.new_record?

    mailing_list = MailingList.find_by(id: group.sac_newsletter_mailing_list_id)
    return unless mailing_list

    if true?(entry.newsletter)
      include_person_in_newsletter(mailing_list)
    else
      mailing_list.exclude_person(entry.person)
    end
  end

  def subscribe_newsletter?
    event.course? &&
      group.root? &&
      group.sac_newsletter_mailing_list_id &&
      !params[:for_someone_else]
  end

  def include_person_in_newsletter(mailing_list)
    # The newsletter mailing list is opt-out and only available for certain roles.
    # (see db/seeds/mailing_lists.rb)
    # Therefore, removing potential exclusions is all to do for a subscription.
    mailing_list
      .subscriptions
      .where(subscriber_id: entry.person.id,
        subscriber_type: Person.sti_name,
        excluded: true)
      .destroy_all
  end

  def assert_participant_cancelable?
    if participant_cancels? && !entry.participant_cancelable?
      entry.errors.add(:base, :invalid)
      throw :abort
    end
  end

  def participant_cancels?
    entry.person == current_user
  end

  def build_entry
    super.tap do |e|
      e.newsletter = true if subscribe_newsletter?
    end
  end

  def send_participation_confirmation_email
    # Ignore Event::ParticipationDecorator
    return unless entry.is_a?(Event::Participation)

    content_key = if entry.state == "assigned"
      Event::ApplicationConfirmationMailer::ASSIGNED
    elsif entry.state == "unconfirmed"
      Event::ApplicationConfirmationMailer::UNCONFIRMED
    else
      Event::ApplicationConfirmationMailer::APPLIED
    end

    Event::ApplicationConfirmationJob.new(entry, content_key).enqueue!
  end
end
