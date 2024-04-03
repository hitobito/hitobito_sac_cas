# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
# == Schema Information
#
# Table name: event_kinds
#
#  id                     :integer          not null, primary key
#  accommodation          :string(255)      default("no_overnight"), not null
#  application_conditions :text(65535)
#  deleted_at             :datetime
#  general_information    :text(65535)
#  kurs_id_fiver          :string(255)
#  maximum_participants   :integer
#  minimum_age            :integer
#  minimum_participants   :integer
#  reserve_accommodation  :boolean          default(TRUE), not null
#  season                 :string(255)
#  short_name             :string(255)
#  training_days          :decimal(5, 2)
#  vereinbarungs_id_fiver :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  cost_center_id         :bigint           not null
#  cost_unit_id           :bigint           not null
#  kind_category_id       :integer
#  level_id               :bigint           not null
#
# Indexes
#
#  index_event_kinds_on_cost_center_id  (cost_center_id)
#  index_event_kinds_on_cost_unit_id    (cost_unit_id)
#  index_event_kinds_on_level_id        (level_id)

module SacCas::Event::Kind
  extend ActiveSupport::Concern

  prepended do
    include I18nEnums
    belongs_to :cost_center
    belongs_to :cost_unit
    belongs_to :level

    validates :cost_center_id, presence: true
    validates :cost_unit_id, presence: true

    validates :kind_category, presence: true
    validates :short_name, presence: true

    SEASONS = %w(winter summer).freeze
    ACCOMMODATIONS = %w(no_overnight hut pension pension_or_hut bivouac).freeze

    i18n_enum :season, SEASONS
    i18n_enum :accommodation, ACCOMMODATIONS
  end

  def push_down_inherited_attributes!
    attrs = Event::Course::INHERITED_ATTRIBUTES.collect { |attr| [attr, send(attr)] }.to_h
    Event::Kind.transaction do
      push_down_events.update_all(attrs.except(:application_conditions).compact)
      push_down_application_conditions!
    end
  end

  private

  def push_down_application_conditions!
    translations.where.not(application_conditions: nil).each do |t|
      kind_attrs = t.attributes.slice(*%w(application_conditions locale created_at updated_at))
      event_attrs = push_down_events.map { |e| kind_attrs.merge(event_id: e.id) }
      Event::Translation.upsert_all(event_attrs) if event_attrs.present?
    end
  end

  def push_down_events
    events.where.not(state: %w(closed canceled))
  end
end
