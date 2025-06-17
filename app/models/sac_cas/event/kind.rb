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
#  maximum_age            :integer
#  ideal_class_size       :integer
#  maximum_class_size     :integer
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

  INHERITABLE_ATTRIBUTES = %w[
    minimum_participants maximum_participants minimum_age
    maximum_age ideal_class_size maximum_class_size season training_days
    reserve_accommodation accommodation cost_center_id cost_unit_id
  ].freeze

  INHERITABLE_TRANSLATED_ATTRIBUTES = %w[
    general_information
    application_conditions
    brief_description
    specialities
    similar_tours
    program
  ].freeze

  prepended do
    include I18nEnums
    has_and_belongs_to_many :course_compensation_categories, foreign_key: :event_kind_id, inverse_of: :course_compensation_category_id
    belongs_to :cost_center
    belongs_to :cost_unit
    belongs_to :level
    translates :brief_description, :specialities, :similar_tours, :program, :seo_text

    # NOTE: When running via rake spec:features presence validations (which
    # probably come from validates_by_schema) are missing
    validates :cost_center_id, presence: true # rubocop:disable Rails/RedundantPresenceValidationOnBelongsTo
    validates :cost_unit_id, presence: true # rubocop:disable Rails/RedundantPresenceValidationOnBelongsTo

    validates :seo_text, length: {allow_nil: true, maximum: 160}
    validates :kind_category, presence: true
    validates :short_name, presence: true

    validate :maximum_age_greater_than_minimum_age, if: -> { maximum_age.present? }

    SEASONS = %w[winter summer].freeze
    ACCOMMODATIONS = %w[no_overnight hut pension pension_or_hut bivouac].freeze

    i18n_enum :season, SEASONS
    i18n_enum :accommodation, ACCOMMODATIONS
  end

  def push_down_inherited_attributes!
    Event::Kind.transaction do
      attrs = INHERITABLE_ATTRIBUTES.index_with { |attr| send(attr) }
      push_down_events.update_all(attrs)
      push_down_translated_attributes!
    end
  end

  def push_down_inherited_attribute!(field)
    if INHERITABLE_TRANSLATED_ATTRIBUTES.include?(field)
      push_down_translated_attributes!(field)
    elsif INHERITABLE_ATTRIBUTES.include?(field)
      push_down_events.update_all(field => send(field))
    end
  end

  private

  def push_down_translated_attributes!(attr = nil)
    event_ids = push_down_events.pluck(:id)
    return if event_ids.blank?

    translations.each do |t|
      fields = attr ? [attr] : INHERITABLE_TRANSLATED_ATTRIBUTES
      attrs = t.attributes.slice("locale", *fields)
      attrs["description"] = attrs.delete("general_information") if attrs.key?("general_information")

      translation_attrs = event_ids.map { |id| attrs.merge(event_id: id) }
      Event::Translation.upsert_all(
        translation_attrs,
        unique_by: [:event_id, :locale],
        returning: false
      )
    end
  end

  def push_down_events
    events.where.not(state: %w[closed canceled])
  end

  def maximum_age_greater_than_minimum_age
    if maximum_age < (minimum_age || 0)
      errors.add(:maximum_age, :greater_than_or_equal_to, count: minimum_age || 0)
    end
  end
end
