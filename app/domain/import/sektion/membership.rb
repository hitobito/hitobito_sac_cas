# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Import
  module Sektion
    class Membership
      attr_reader :row, :placeholder_contact_group, :current_ability

      BEITRAGSKATEGORIEN = {
        'EINZEL' => :einzel,
        'JUGEND' => :jugend,
        'FAMILIE' => :familie,
        'FREI KIND' => :familie,
        'FREI FAM' => :familie
      }.freeze

      TARGET_ROLE = Group::SektionsMitglieder::Mitglied.sti_name
      DEFAULT_DELETE_ON = Date.new(2024, 12, 31)
      UNKNOWN_JOINING_DATE = Date.new(1900, 1, 1)

      def initialize(row, group:, placeholder_contact_group:, current_ability:)
        @row = row
        @group = group
        @placeholder_contact_group = placeholder_contact_group
        @current_ability = current_ability
      end

      def person
        @person ||= ::Person.find_by(id: navision_id)
      end

      def role
        @role ||= build_role
      end

      def valid?
        @valid ||= person&.valid? && role.valid? && !abo?
      end

      def errors
        @errors ||= valid? ? [] : build_error_messages
      end

      def import!
        role.transaction do
          role.save!
          assign_household(row[:household_key])
          remove_placeholder_contact_role
        end
      end

      def to_s
        "#{person.to_s(:list)} (#{navision_id})"
      end

      private

      def assign_household(household_key)
        return if household_key.blank?
        return if household_key == person.household_key # already assigned

        if (other_person = ::Person.find_by(household_key: household_key))
          # Household key exists already, assign person to existing household
          ::Person::Household.new(
            person,
            current_ability,
            other_person,
            current_ability.user
          ).assign.persist!
        else
          # Household key does not exist yet, save it on the person
          person.update!(household_key: household_key)
        end
      end

      def remove_placeholder_contact_role
        Group::ExterneKontakte::Kontakt.where(person: person,
                                              group: placeholder_contact_group).delete_all
      end

      def build_role
        person.roles.
          where(group_id: @group&.id, type: Group::SektionsMitglieder::Mitglied.sti_name).
          first_or_initialize.tap do |role|
          role.attributes = {
            beitragskategorie: BEITRAGSKATEGORIEN[row[:beitragskategorie]],
            created_at: joining_date,
            deleted_at: quitted? ? last_exit_date : nil,
            delete_on: quitted? ? nil : DEFAULT_DELETE_ON
          }
        end
      end

      def joining_date
        if last_joining_date.present? && last_joining_date != UNKNOWN_JOINING_DATE
          last_joining_date
        else
          joining_year
        end
      end

      def last_joining_date
        parse_date(row[:last_joining_date])
      end

      def joining_year
        Date.new(row[:joining_year].to_i) if /\A\d{4}\z/.match?(row[:joining_year].to_s)
      end

      def last_exit_date
        parse_date(row[:last_exit_date])
      end

      def parse_date(value)
        Date.parse(value.to_s)
      rescue Date::Error
        nil
      end

      def beitragskategorie
        BEITRAGSKATEGORIEN[row[:beitragskategorie].to_s]
      end

      def navision_id
        Integer(row[:navision_id].to_s.sub!(/^0*/, ''))
      end

      def quitted?
        row[:member_type] == 'Ausgetreten'
      end

      def abo?
        row[:member_type] == 'Abonnent'
      end

      def build_error_messages
        return "Person #{navision_id} existiert nicht" unless person

        [person.errors.full_messages, role.errors.full_messages, member_type_error]
          .flatten.compact.join(', ').tap do |messages|
            messages.prepend("#{self}: ") if messages.present?
          end
      end

      def member_type_error
        'Abonnent ist nicht gültig' if abo?
      end
    end
  end
end
