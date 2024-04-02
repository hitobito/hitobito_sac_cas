# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

#  id                               :integer          not null, primary key
#  accomodation                     :string(255)      default("no_overnight"), not null
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
#  maximum_participants             :integer
#  minimum_age                      :integer
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
#  index_events_on_kind_id  (kind_id)
#  index_events_on_cost_center_id       (cost_center_id)
#  index_events_on_cost_unit_id         (cost_unit_id)
#  index_events_on_kind_id              (kind_id)
#  index_events_on_shared_access_token  (shared_access_token)

module SacCas::Event::Course
  extend ActiveSupport::Concern

  prepended do
    include I18nEnums
    LANGUAGES = %w(de_fr fr de it).freeze
    START_POINTS_OF_TIME = %w(day evening).freeze

    I18N_KIND = 'activerecord.attributes.event/kind'

    i18n_enum :language, LANGUAGES
    i18n_enum :season, Event::Kind::SEASONS, i18n_prefix: "#{I18N_KIND}.seasons"
    i18n_enum :accomodation, Event::Kind::ACCOMODATIONS, i18n_prefix: "#{I18N_KIND}.accomodations"
    i18n_enum :start_point_of_time, START_POINTS_OF_TIME

    self.used_attributes += [
      :language,
      :cost_center_id,
      :cost_unit_id,
      :annual,
      :link_participants,
      :link_leaders,
      :link_survey,
      :reserve_accommodation,
      :accomodation,
      :season,
      :start_point_of_time,
      :minimum_age
    ]

    self.used_attributes -= [
      :cost,
      :waiting_list,
      :tentative_applications
    ]

    belongs_to :cost_center, optional: true
    belongs_to :cost_unit, optional: true
    validates :number, presence: true, uniqueness: { if: :number }

    delegate :level, to: :kind, allow_nil: true

    attribute :waiting_list, default: false
  end

  def minimum_age
    self.read_attribute(:minimum_age)
  end
end
