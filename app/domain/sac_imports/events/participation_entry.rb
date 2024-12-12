# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  module Events
    class ParticipationEntry
      LOCALES = [:de, :fr, :it].freeze
      ATTRS_REGULAR = [:person_id, :state, :additional_information, :canceled_at, :cancel_statement, :actual_days, :price]
      ATTRS_BOOLEAN = [:qualified, :subsidy]
      ATTRS_BELONGS_TO = [:event_number]

      ROLE_TYPES = {
        "leader" => Event::Course::Role::Leader,
        "assistant_leader" => Event::Course::Role::AssistantLeader,
        "participant" => Event::Course::Role::Participant
      }

      attr_reader :row, :warnings

      delegate :errors, to: :participation

      def initialize(row)
        @row = row
        @warnings = []
        build_participation
      end

      def import!
        participation.save!
      end

      def valid?
        !!event && participation.valid?
      end

      def error_messages
        errors.full_messages.join(", ")
      end

      def participation
        @participation ||= Event::Participation.find_or_initialize_by(event: event, person_id: row.person_id)
      end

      def event
        return @event if defined?(@event)

        @event = Event.where(number: row.event_number).first
        @warnings << "Event with number '#{row.event_number}' couldn't be found" unless @event
        @event
      end

      def build_participation
        participation.attributes = regular_attrs
        participation.attributes = boolean_attrs
        participation.price_category = price_category
        build_role
        build_application
      end

      def regular_attrs
        ATTRS_REGULAR.each_with_object({}) do |attr, hash|
          hash[attr] = value(attr)
        end
      end

      def boolean_attrs
        ATTRS_BOOLEAN.each_with_object({}) do |attr, hash|
          hash[attr] = value(attr) == "1"
        end
      end

      def price_category
        category = row.price_category
        return if category.blank?

        if Event::Participation.price_categories.key?(category)
          category
        else
          @warnings << "Price category '#{category}' is not known"
          nil
        end
      end

      def build_role
        role = participation.roles.find_or_initialize_by(type: role_type)
        role.label = row.role_label
        role.self_employed = row.role_self_employed == "1"
        role
      end

      def build_application
        return unless event

        participation.init_application
        return unless participation.application

        participation.application.approved = !participation.state.in?(%w[rejected applied unconfirmed])
        participation.application.rejected = participation.state == "rejected"
      end

      def role_type
        type = ROLE_TYPES[row.role_type]
        unless type
          @warnings << "Role type '#{row.role_type}' is not known"
          type = ROLE_TYPES.fetch("participant")
        end
        type.sti_name
      end

      def value(attr)
        row.public_send(attr)
      end
    end
  end
end
