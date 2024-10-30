# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::Event::Participation
  extend ActiveSupport::Concern

  prepended do
    include I18nEnums
    include CapitalizedDependentErrors

    enum price_category: {
      price_member: 0,
      price_regular: 1,
      price_subsidized: 2,
      price_js_active_member: 3,
      price_js_active_regular: 4,
      price_js_passive_member: 5,
      price_js_passive_regular: 6
    }

    i18n_enum :invoice_state, ExternalInvoice::STATES, scopes: true, queries: true

    before_save :update_previous_state, if: :state_changed?

    attr_accessor :adult_consent, :terms_and_conditions, :newsletter, :check_root_conditions

    has_many :external_invoices, as: :link, dependent: :restrict_with_error

    validates :adult_consent, :terms_and_conditions, acceptance: {if: :check_root_conditions}
    validates :actual_days, numericality: {greater_than_or_equal_to: 0, allow_blank: true}
    validate :assert_actual_days_size

    after_update :send_application_canceled_email, if: :state_changed_to_canceled?
  end

  def subsidy_amount
    subsidy ? event.price_subsidized : 0
  end

  def course_pricing
    price, category = if person.sac_membership_active?
      subsidy ? [subsidy_amount, :price_subsidized] : [event.price_member, :price_member]
    else
      [event.price_regular, :price_regular]
    end

    {price: price, price_category: category}
  end

  def subsidizable?
    event.course? && event.price_subsidized.present? && person.roles.any? do |role|
      role.class.include?(SacCas::Role::MitgliedStammsektion)
    end
  end

  def participant_cancelable?
    event.applications_cancelable? && event.state != "annulled" &&
      event.dates.map(&:start_at).min.future?
  end

  def check_root_conditions!
    # set values to false because validates acceptance does not work with nil
    self.adult_consent ||= false
    self.terms_and_conditions ||= false
    self.check_root_conditions = true
  end

  private

  def assert_actual_days_size
    return if actual_days.blank?

    if actual_days > event.total_duration_days
      errors.add(:actual_days, :longer_than_event_duration)
    end
  end

  def update_previous_state
    if %w[canceled annulled].include?(state)
      self.previous_state = state_was
    end
  end

  def state_changed_to_canceled?
    saved_change_to_attribute(:state)&.second == "canceled"
  end

  def send_application_canceled_email
    Event::ParticipationCanceledMailer.confirmation(self).deliver_later
  end
end
