# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::Event::Participation
  extend ActiveSupport::Concern

  MEANS_OF_TRANSPORT = %w[public car legs].freeze

  SELF_EMPLOYED_LEADER_ROLES = [
    Group::SacCasKurskader::KursleitungSelbstaendig,
    Group::SacCasKurskader::KursleitungAspirantSelbstaendig,
    Group::SacCasKurskader::KlassenlehrerSelbstaendig,
    Group::SacCasKurskader::KlassenlehrerAspirantSelbstaendig
  ]

  delegate :sac_membership_active?, :membership_years, :membership_number, :correspondence,
    to: :person

  prepended do # rubocop:todo Metrics/BlockLength
    include I18nEnums
    include CapitalizedDependentErrors
    include Events::Participations::PriceCalculatable

    enum :price_category, [:price_member, :price_regular, :price_subsidized, :price_special]

    i18n_enum :invoice_state, ExternalInvoice::STATES, scopes: true, queries: true
    i18n_enum :means_of_transport, MEANS_OF_TRANSPORT

    paper_trail_options[:skip] |= ["previous_state"]

    before_validation :round_actual_days
    before_save :update_previous_state, if: :state_changed?

    attr_accessor :adult_consent, :terms_and_conditions, :newsletter, :check_root_conditions

    # rubocop:todo Rails/InverseOf
    has_many :external_invoices, as: :link, dependent: :restrict_with_error
    # rubocop:enable Rails/InverseOf

    validates :adult_consent, :terms_and_conditions, acceptance: {if: :check_root_conditions}
    validates :actual_days, numericality: {greater_than_or_equal_to: 0, allow_blank: true}
    validate :assert_actual_days_size, if: :actual_days_changed?
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

  def highest_leader_role_type
    @highest_leader_role_type ||=
      (Event::Course.leader_types.map(&:sti_name) & roles.map(&:type)).first&.demodulize&.underscore
  end

  # Returns the matching tour sektion if person has a stamm- or zusatzmitgliedschaft in it.
  # Falls back to stammsektion if they have no membership in any of the tour sektionen.
  # Returns nil if person has no active membership at all.
  def tour_sektion
    raise "Only use on tour participations" unless event.tour?

    return nil unless person.sac_membership_active?

    stammsektion = person.sac_membership_stammsektion
    membership_in_tour_sektion = (
      ([stammsektion] + person.sac_membership_zusatzsektionen) & event.groups
    ).first

    membership_in_tour_sektion || stammsektion
  end

  private

  def round_actual_days
    if new_record? && roles.any? { |r| r.class.participant? }
      self.actual_days ||= event.training_days
    end

    self.actual_days = (actual_days * 2).round / 2.0 if actual_days
  end

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
end
