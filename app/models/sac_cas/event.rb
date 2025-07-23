# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

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
#  link_external_site               :string(255)
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

module SacCas::Event
  extend ActiveSupport::Concern

  prepended do
    self.used_attributes -= [
      :required_contact_attrs,
      :hidden_contact_attrs
    ]

    translates :brief_description, :specialities, :similar_tours, :program

    validates :training_days, numericality: {less_than_or_equal_to: :total_duration_days, allow_nil: true}
  end

  module ClassMethods
    def receiving_reminders = where.not(state: [:closed, :canceled])
  end

  def total_duration_days
    dates.sum { _1.duration.days }
  end

  def states?
    is_a?(Events::State)
  end
end
