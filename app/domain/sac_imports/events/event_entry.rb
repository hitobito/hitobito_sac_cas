# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  module Events
    class EventEntry
      LOCALES = [:de, :fr, :it].freeze
      ATTRS_TRANSLATED = [:name, :description, :application_conditions, :brief_description,
        :specialities, :similar_tours, :program]
      ATTRS_REGULAR = [:number, :state, :contact_id, :location, :minimum_age, :maximum_age,
        :minimum_participants, :maximum_participants, :ideal_class_size, :maximum_class_size,
        :training_days, :season, :accommodation, :meals, :language, :start_point_of_time,
        :application_opening_at, :application_closing_at, :signature_confirmation_text,
        :price_member, :price_regular, :price_subsidized, :price_js_active_member,
        :price_js_active_regular, :price_js_passive_member, :price_js_passive_regular,
        :link_participants, :link_leaders, :link_survey, :book_discount_code]
      ATTRS_BOOLEAN = [:reserve_accommodation, :globally_visible, :annual, :external_applications,
        :participations_visible, :priorization, :automatic_assignment, :signature,
        :signature_confirmation, :applications_cancelable, :display_booking_info]
      ATTRS_BELONGS_TO = [:kind, :cost_center, :cost_unit]

      attr_reader :row, :associations, :warnings

      delegate :valid?, :errors, to: :event

      def initialize(row, associations)
        @row = row
        @associations = associations
        @warnings = []
        build_event
      end

      def import!
        event.save!
      end

      def error_messages
        errors.full_messages.join(", ")
      end

      def event
        @event ||= Event::Course.find_or_initialize_by(number: row.number)
      end

      def build_event
        event.attributes = regular_attrs
        event.attributes = boolean_attrs
        event.attributes = belongs_to_attrs
        event.canceled_reason = canceled_reason
        LOCALES.each do |locale|
          event.attributes = translated_attrs(locale)
        end
        event.groups = [associations.fetch(:groups).fetch(:root)]
        build_date
        normalize_event
      end

      def regular_attrs
        ATTRS_REGULAR.each_with_object({}) do |attr, hash|
          hash[attr] = value(attr)
        end
      end

      def translated_attrs(locale)
        ATTRS_TRANSLATED.each_with_object({locale: locale}) do |attr, hash|
          val = value(:"#{attr}_#{locale}")
          hash[attr] = strip_paragraph(val) unless val.nil?
        end
      end

      def belongs_to_attrs
        ATTRS_BELONGS_TO.each_with_object({}) do |attr, hash|
          hash[:"#{attr}_id"] = association_id(attr, value(attr))
        end
      end

      def association_id(attr, value)
        return nil if value.nil?

        associations.fetch(attr.to_s.pluralize.to_sym).fetch(value) do
          @warnings << "#{attr} with value #{value} couldn't be found"
          nil
        end
      end

      def boolean_attrs
        ATTRS_BOOLEAN.each_with_object({}) do |attr, hash|
          hash[attr] = value(attr) == "1"
        end
      end

      def build_date
        event.dates.find_or_initialize_by(
          label: value(:date_label),
          location: value(:date_location),
          start_at: value(:date_start_at),
          finish_at: value(:date_finish_at)
        )
      end

      def canceled_reason
        canceled_reason_value = value(:canceled_reason)
        if canceled_reason_value == "not_applicable"
          "weather"
        else
          canceled_reason_value
        end
      end

      def normalize_event
      end

      def value(attr)
        row.public_send(attr)
      end

      def strip_paragraph(text)
        match = text.match(/\A<p>(.*?)<\/p>\z/m)
        if match && text.scan("<p>").count == 1
          match[1]
        else
          text
        end
      end
    end
  end
end
