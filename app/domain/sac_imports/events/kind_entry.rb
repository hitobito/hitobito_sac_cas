# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  module Events
    class KindEntry
      LOCALES = [:de, :fr, :it].freeze
      ATTRS_TRANSLATED = [:label, :general_information, :application_conditions]
      ATTRS_REGULAR = [:short_name, :minimum_age, :maximum_age, :minimum_participants,
        :maximum_participants, :ideal_class_size, :maximum_class_size, :training_days,
        :season, :accommodation]
      ATTRS_BOOLEAN = [:reserve_accommodation, :section_may_create]
      ATTRS_STRING_BELONGS_TO = [:cost_center, :cost_unit] # foreign key is a string
      ATTRS_INT_BELONGS_TO = [:kind_category, :level] # foreign key is an int

      attr_reader :row, :associations, :warnings

      delegate :valid?, :errors, to: :kind

      def initialize(row, associations)
        @row = row
        @associations = associations
        @warnings = []
        build_kind
      end

      def import!
        kind.save!
      end

      def error_messages
        errors.full_messages.join(", ")
      end

      def kind
        @kind ||= Event::Kind.find_or_initialize_by(short_name: row.short_name)
      end

      def build_kind
        kind.attributes = regular_attrs
        kind.attributes = boolean_attrs
        kind.attributes = belongs_to_int_attrs
        kind.attributes = belongs_to_string_attrs
        LOCALES.each do |locale|
          kind.attributes = translated_attrs(locale)
        end
        kind.course_compensation_category_ids = select_course_compensation_category_ids
        build_kind_qualification_kinds
        normalize_kind
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

      def belongs_to_string_attrs
        ATTRS_STRING_BELONGS_TO.each_with_object({}) do |attr, hash|
          hash[:"#{attr}_id"] = association_id(attr, value(attr))
        end
      end

      def belongs_to_int_attrs
        ATTRS_INT_BELONGS_TO.each_with_object({}) do |attr, hash|
          hash[:"#{attr}_id"] = association_id(attr, value(attr)&.to_i)
        end
      end

      def association_id(attr, value)
        return nil if value.nil?

        associations.fetch(attr.to_s.pluralize.to_sym).fetch(value) do
          @warnings << "#{attr} with value '#{value}' couldn't be found"
          nil
        end
      end

      def boolean_attrs
        ATTRS_BOOLEAN.each_with_object({}) do |attr, hash|
          hash[attr] = value(attr) == "1"
        end
      end

      def select_course_compensation_category_ids
        row.course_compensation_categories.to_s.split(",").map do |category|
          association_id(:course_compensation_category, category.strip)
        end.compact.uniq
      end

      def build_kind_qualification_kinds
        Event::KindQualificationKind::CATEGORIES.each do |category|
          row.public_send(category).to_s.split(",").each do |quali_kind|
            quali_kind_id = association_id(:qualification_kind, quali_kind.strip)
            next unless quali_kind_id

            kind.event_kind_qualification_kinds.find_or_initialize_by(
              qualification_kind_id: quali_kind_id,
              category: category,
              role: "participant"
            )
          end
        end
      end

      def normalize_kind
        kind.maximum_age = nil if kind.maximum_age&.zero?
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
