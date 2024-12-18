# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  module Events
    class ExternalTrainingEntry
      ATTRS_REGULAR = [:person_id, :name, :provider, :start_at, :finish_at, :training_days, :link, :remarks]
      ATTRS_BELONGS_TO = [:event_kind]

      attr_reader :row, :associations, :warnings

      delegate :errors, to: :external_training

      def initialize(row, associations)
        @row = row
        @associations = associations
        @warnings = []
        build_external_training
      end

      def import!
        external_training.save!
      end

      def valid?
        external_training.valid?
      end

      def error_messages
        errors.full_messages.join(", ")
      end

      def external_training
        @external_training ||= ExternalTraining.new
      end

      def build_external_training
        external_training.attributes = regular_attrs
        external_training.event_kind_id = association_id(:event_kind, value(:event_kind))
      end

      def regular_attrs
        ATTRS_REGULAR.each_with_object({}) do |attr, hash|
          hash[attr] = value(attr)
        end
      end

      def association_id(attr, value)
        return nil if value.nil?

        associations.fetch(attr.to_s.pluralize.to_sym).fetch(value) do
          @warnings << "#{attr} with value #{value} couldn't be found"
          nil
        end
      end

      def value(attr)
        row.public_send(attr)
      end
    end
  end
end
