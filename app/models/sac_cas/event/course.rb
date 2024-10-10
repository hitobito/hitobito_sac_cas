# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: events
#
#  id                               :integer          not null, primary key
#  accommodation                    :string(255)      default("no_overnight"), not null
#  annual                           :boolean          default(TRUE), not null
#  applicant_count                  :integer          default(0)
#  application_closing_at           :date
#  application_conditions           :text(65535)
#  application_opening_at           :date
#  applications_cancelable          :boolean          default(FALSE), not null
#  cost                             :string(255)
#  description                      :text(65535)
#  display_booking_info             :boolean          default(TRUE), not null
#  external_applications            :boolean          default(FALSE)
#  globally_visible                 :boolean
#  hidden_contact_attrs             :text(65535)
#  language                         :string(255)
#  link_leaders                     :string(255)
#  link_participants                :string(255)
#  link_survey                      :string(255)
#  location                         :text(65535)
#  minimum_participants             :integer
#  maximum_participants             :integer
#  minimum_age                      :integer
#  maximum_age                      :integer
#  ideal_class_size                 :integer
#  maximum_class_size               :integer
#  motto                            :string(255)
#  name                             :string(255)
#  notify_contact_on_participations :boolean          default(FALSE), not null
#  number                           :string(255)
#  participant_count                :integer          default(0)
#  participations_visible           :boolean          default(FALSE), not null
#  priorization                     :boolean          default(FALSE), not null
#  required_contact_attrs           :text(65535)
#  requires_approval                :boolean          default(FALSE), not null
#  reserve_accommodation            :boolean          default(TRUE), not null
#  season                           :string(255)
#  shared_access_token              :string(255)
#  signature                        :boolean
#  signature_confirmation           :boolean
#  signature_confirmation_text      :string(255)
#  start_point_of_time              :string(255)
#  state                            :string(60)
#  teamer_count                     :integer          default(0)
#  tentative_applications           :boolean          default(FALSE), not null
#  training_days                    :decimal(5, 2)
#  type                             :string(255)
#  unconfirmed_count                :integer          default(0), not null
#  waiting_list                     :boolean          default(TRUE), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  application_contact_id           :integer
#  contact_id                       :integer
#  cost_center_id                   :bigint
#  cost_unit_id                     :bigint
#  creator_id                       :integer
#  kind_id                          :integer
#  updater_id                       :integer
#
# Indexes
#
#  index_events_on_cost_center_id       (cost_center_id)
#  index_events_on_cost_unit_id         (cost_unit_id)
#  index_events_on_kind_id              (kind_id)
#  index_events_on_shared_access_token  (shared_access_token)
#

module SacCas::Event::Course
  extend ActiveSupport::Concern

  LANGUAGES = %w[de_fr fr de it].freeze
  MEALS = %w[breakfast half_board lunch self_cooking full_board].freeze
  START_POINTS_OF_TIME = %w[day evening].freeze
  CANCELED_REASONS = %w[minimum_participants no_leader weather].freeze

  WEAK_VALIDATION_STATES = %w[created canceled].freeze

  I18N_KIND = "activerecord.attributes.event/kind"

  LEADER_ROLES = [Event::Role::Leader, Event::Role::AssistantLeader].map(&:sti_name)

  INHERITED_ATTRIBUTES = [
    :application_conditions, :minimum_participants, :maximum_participants, :minimum_age,
    :maximum_age, :ideal_class_size, :maximum_class_size, :season, :training_days,
    :reserve_accommodation, :accommodation, :cost_center_id, :cost_unit_id
  ]

  PRICE_ATTRIBUTES = %i[price_member price_regular price_subsidized price_js_active_member
    price_js_active_regular price_js_passive_member price_js_passive_regular]

  prepended do # rubocop:disable Metrics/BlockLength
    include I18nEnums
    include Events::Courses::State

    translates :brief_description, :specialities, :similar_tours, :program

    i18n_enum :language, LANGUAGES
    i18n_enum :season, Event::Kind::SEASONS, i18n_prefix: "#{I18N_KIND}.seasons"
    i18n_enum :meals, MEALS, i18n_prefix: "activerecord.attributes.event/course.meals_options"
    i18n_enum :accommodation,
      Event::Kind::ACCOMMODATIONS,
      i18n_prefix: "#{I18N_KIND}.accommodations"
    i18n_enum :start_point_of_time, START_POINTS_OF_TIME
    i18n_enum :canceled_reason, CANCELED_REASONS, i18n_prefix: "activerecord.attributes.event/course.canceled_reasons"
    enum canceled_reason: CANCELED_REASONS

    self.role_types = [Event::Role::Leader,
      Event::Role::AssistantLeader,
      Event::Course::Role::Participant]

    self.used_attributes += [
      :language,
      :cost_center_id,
      :cost_unit_id,
      :annual,
      :link_participants,
      :link_leaders,
      :link_survey,
      :reserve_accommodation,
      :accommodation,
      :meals,
      :season,
      :start_point_of_time,
      :minimum_age,
      :maximum_age,
      :ideal_class_size,
      :maximum_class_size,
      :brief_description,
      :specialities,
      :similar_tours,
      :program,
      :book_discount_code,
      *PRICE_ATTRIBUTES
    ]

    self.used_attributes -= [
      :cost,
      :motto,
      :waiting_list,
      :tentative_applications,
      :required_contact_attrs,
      :hidden_contact_attrs
    ]

    self.possible_participation_states = %w[unconfirmed applied rejected assigned summoned
      attended absent canceled annulled]
    self.active_participation_states = %w[assigned summoned attended]

    self.revoked_participation_states = %w[rejected canceled absent annulled]

    self.countable_participation_states = %w[unconfirmed applied assigned summoned attended absent]

    belongs_to :cost_center, optional: true
    belongs_to :cost_unit, optional: true
    validates :number, presence: true, uniqueness: {if: :number}
    validates :description, :application_opening_at, :application_closing_at, :contact_id,
      :location, :language, :cost_center_id, :cost_unit_id, :season, :start_point_of_time,
      :accommodation, :price_member, :price_regular,
      presence: {unless: :weak_validation_state?}

    delegate :level, to: :kind, allow_nil: true

    attribute :waiting_list, default: false
  end

  def minimum_age
    read_attribute(:minimum_age)
  end

  def default_participation_state(participation, for_someone_else = false)
    return "unconfirmed" if super == "applied" && (places_available? && !automatic_assignment?)

    super
  end

  def leaders
    Person.where(id: participations.joins(:roles)
      .where(roles: {type: LEADER_ROLES}).pluck(:person_id))
  end

  private

  def weak_validation_state?
    state.blank? || WEAK_VALIDATION_STATES.include?(state)
  end
end
