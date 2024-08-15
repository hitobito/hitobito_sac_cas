# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  module Sektion
    class Membership
      attr_reader :row, :placeholder_contact_group, :current_ability

      BEITRAGSKATEGORIEN = {
        "EINZEL" => :adult,
        "JUGEND" => :youth,
        "FAMILIE" => :family,
        "FREI KIND" => :family,
        "FREI FAM" => :family
      }.freeze

      TARGET_ROLE_TYPE = Group::SektionsMitglieder::Mitglied
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
        # Use context :import to skip the assert_adult_household_people_mitglieder_count
        # validation that must be ignored during import
        @valid ||= role.valid?(:import) && !abo?
      end

      def errors
        @errors ||= valid? ? [] : build_error_messages
      end

      def import!
        role.transaction do
          mark_family_main_person
          assign_household(row[:household_key])
          # Use context :import to skip the `assert_adult_family_mitglieder_count`
          # and `assert_single_family_main_person` validations that must be ignored during import
          role.save!(context: :import)
          remove_placeholder_contact_role
          assign_beguenstigt
          assign_ehrenmitglied
        end
      end

      def to_s
        "#{person.to_s(:list)} (#{navision_id})"
      end

      private

      def assign_beguenstigt
        return unless beguenstigt?

        Group::SektionsMitglieder::Beguenstigt.find_or_create_by!(person: person, group: @group)
      end

      def assign_ehrenmitglied
        return unless ehrenmitglied?

        Group::SektionsMitglieder::Ehrenmitglied.find_or_create_by!(person: person, group: @group)
      end

      def assign_household(household_key)
        return if household_key.blank?
        household_key = household_key.round(0)
        return if household_key == person.household_key # already assigned

        if (other_person = ::Person.find_by(household_key: household_key))
          # Household key exists already, assign person to existing household
          household = Household.new(other_person, maintain_sac_family: false)
          household.add(person)
          household.save!
        else
          # Household key does not exist yet, save it on the person
          person.update!(household_key: household_key)
        end
      end

      def mark_family_main_person
        person.update(sac_family_main_person: true) if family_main_person?
      end

      def remove_placeholder_contact_role
        Group::ExterneKontakte::Kontakt
          .where(person: person,
            group: placeholder_contact_group)
          .find_each(&:really_destroy!)
      end

      def build_role
        return Role.new unless person

        person.roles
          .where(group_id: @group&.id, type: TARGET_ROLE_TYPE.sti_name)
          .first_or_initialize.tap do |role|
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
        Integer(row[:navision_id].to_s.sub!(/^0*/, ""))
      end

      def quitted?
        row[:member_type] == "Ausgetreten"
      end

      def abo?
        row[:member_type] == "Abonnent"
      end

      def beguenstigt?
        row[:beguenstigt] == "Ja"
      end

      def ehrenmitglied?
        row[:ehrenmitglied] == "Ja"
      end

      def family_main_person?
        row[:beitragskategorie] == "FAMILIE"
      end

      def build_error_messages
        return "Person #{navision_id} existiert nicht" unless person

        [role.errors.full_messages, member_type_error]
          .flatten.compact.join(", ").tap do |messages|
            messages.prepend("#{self}: ") if messages.present?
          end
      end

      def member_type_error
        "Abonnent ist nicht gültig" if abo?
      end
    end
  end
end
