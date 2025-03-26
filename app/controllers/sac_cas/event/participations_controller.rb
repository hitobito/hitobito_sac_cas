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

    self.permitted_attrs += %i[subsidy adult_consent terms_and_conditions newsletter price_category]

    around_create :proceed_wizard
    after_create :subscribe_newsletter
    after_summon :enqueue_invoice_job
    after_assign :enqueue_confirmation_job # send_confirmation_email in core checks current_user_interested_in_mail? which should be irrelevant here
    before_cancel :assert_participant_cancelable?
  end

  def cancel
    cancel_invoices
    entry.cancel_statement = params.dig(:event_participation, :cancel_statement)
    entry.canceled_at = params.dig(:event_participation, :canceled_at) || Time.zone.today
    entry.canceled_at = Time.zone.today if participant_cancels?
    send_application_canceled_email if send_email? || participant_cancels?
    change_state("canceled", "cancel")
  end

  def summon
    send_application_summoned_email if send_email?
    change_state("summoned", "summon")
  end

  def new
    @step = "answers" if event.course?
    super
  end

  private

  def enqueue_confirmation_job
    Event::ParticipationConfirmationJob.new(entry).enqueue!
  end

  def send_application_canceled_email
    Event::ParticipationCanceledMailer.confirmation(entry).deliver_later
  end

  def send_application_summoned_email
    Event::ParticipationMailer.summon(entry).deliver_later
  end

  def permitted_attrs
    permitted = self.class.permitted_attrs.dup
    permitted << :actual_days if can?(:edit_actual_days, entry)
    permitted
  end

  def permitted_params
    super.tap do |permitted|
      calculate_price(permitted)
    end
  end

  def calculate_price(permitted)
    permitted.delete(:price_category) if entry.person_id == current_user.id

    price_category = permitted[:price_category]
    if entry.new_record? && !params[:for_someone_else]
      permitted[:subsidy] = false unless entry.subsidizable?
      permitted[:price_category] = price_category = determine_price_category(permitted[:subsidy])
    end

    if price_category == "former"
      permitted.delete(:price_category)
    elsif permitted.key?(:price_category)
      permitted[:price] = price_for_category(price_category)
    end
  end

  def determine_price_category(subsidy)
    if entry.person.sac_membership_active?
      subsidy ? :price_subsidized : :price_member
    else
      :price_regular
    end
  end

  def price_for_category(price_category)
    price_category.blank? ? nil : @event.send(price_category)
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

    MailingList
      .find_by(id: group.sac_newsletter_mailing_list_id)
      &.subscribe_if(entry.person, true?(entry.newsletter))
  end

  def subscribe_newsletter?
    event.course? &&
      group.root? &&
      group.sac_newsletter_mailing_list_id &&
      !params[:for_someone_else]
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

  def enqueue_invoice_job
    ExternalInvoice::CourseParticipation.invoice!(entry) unless ExternalInvoice::CourseParticipation.exists?(link: entry)
  end

  def cancel_invoices
    entry.person.external_invoices.where(link: entry).find_each do |invoice|
      invoice.update!(state: :cancelled)
      Invoices::Abacus::CancelInvoiceJob.new(invoice).enqueue!
    end

    if params.dig(:invoice_option) == "standard"
      ExternalInvoice::CourseAnnulation.invoice!(entry)
    elsif params.dig(:invoice_option) == "custom"
      ExternalInvoice::CourseAnnulation.invoice!(entry, custom_price: params.dig(:custom_price).to_i)
    end
  end
end
