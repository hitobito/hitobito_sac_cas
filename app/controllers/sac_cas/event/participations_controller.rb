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

    self.permitted_attrs += %i[subsidy adult_consent terms_and_conditions newsletter price_category price]

    around_create :proceed_wizard
    after_create :subscribe_newsletter
    after_save :update_participation_price
    after_summon :enqueue_invoice_job
    before_cancel :assert_participant_cancelable?
    after_cancel :cancel_invoices
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

  def assign_attributes
    permitted = permitted_params
    permitted.delete(:price_category) if keep_former_price?
    entry.attributes = permitted
  end

  def keep_former_price?
    permitted_params[:price_category] == "former"
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
    subscriptions = Person::Subscriptions.new(entry.person)

    if true?(entry.newsletter)
      subscriptions.subscribe(mailing_list)
    else
      subscriptions.unsubscribe(mailing_list)
    end
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

    ExternalInvoice::CourseAnnulation.invoice!(entry)
  end

  def update_participation_price
    return if keep_former_price?

    entry.update!(price: entry.price_category.nil? ? nil : @event.send(entry.price_category))
  end
end
