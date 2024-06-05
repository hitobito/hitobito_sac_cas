# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class Member

      MAIN_MEMBERSHIP_ROLE = Group::SektionsMitglieder::Mitglied
      ADDITIONAL_SECTION_ROLE = Group::SektionsMitglieder::MitgliedZusatzsektion
      NEW_ENTRY_ROLE = Group::SektionsNeuanmeldungenNv::Neuanmeldung
      NEW_ADDITIONAL_SECTION_ROLE = Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion

      attr_reader :person, :context
      attr_writer :sac_magazine_mailing_list

      delegate :id, :to_s, :language, :sac_family_main_person?, to: :person
      delegate :date, to: :context

      # Person model
      def initialize(person, context)
        @person = person
        @context = context
      end

      def age
        @age ||= person.years(Date.new(date.year, 12, 31))
      end

      def membership_years
        # person must have been loaded with .with_membership_years(date)
        person.membership_years
      end

      def main_membership_role
        @main_membership_role ||= active_roles_of_type(MAIN_MEMBERSHIP_ROLE).first
      end

      def additional_membership_roles
        @additional_membership_roles ||= active_roles_of_type(ADDITIONAL_SECTION_ROLE)
      end

      def new_entry_role
        @new_entry_role ||= active_roles_of_type(NEW_ENTRY_ROLE).first
      end

      def new_additional_section_membership_roles
        active_roles_of_type(NEW_ADDITIONAL_SECTION_ROLE)
      end

      def new_additional_section_membership_role(section)
        new_additional_section_membership_roles.find { |r| r.layer_group.id == section.id }
      end

      def sac_honorary_member?
        return @sac_honorary_member if defined?(@sac_honorary_member)

        @sac_honorary_member = active_roles_of_type(Group::Ehrenmitglieder::Ehrenmitglied).present?
      end

      def section_honorary_member?(section)
        active_roles_of_type(Group::SektionsMitglieder::Ehrenmitglied)
          .any? { |r| r.layer_group.id == section.id }
      end

      def section_benefited_member?(section)
        active_roles_of_type(Group::SektionsMitglieder::Beguenstigt)
          .any? { |r| r.layer_group.id == section.id }
      end

      def living_abroad?
        !person.swiss?
      end

      def sac_magazine?
        return @sac_magazine if defined?(@sac_magazine)

        @sac_magazine = sac_magazine_mailing_list.subscribed?(person)
      end

      def paying_person?(role)
        !role.beitragskategorie.family? || sac_family_main_person?
      end

      def service_fee?(role)
        paying_person?(role) ||
          additional_membership_roles.any? { |r| !r.beitragskategorie.family? }
      end

      def membership_cards?(role)
        paying_person?(role) &&
          (role == main_membership_role || role == new_entry_role)
      end

      def family_members
        person
          .household_people
          .order_by_name
          .includes(:roles)
          .select { |p| active_main_membership_role?(p) }
      end

      private

      def sac_magazine_mailing_list
        @sac_magazine_mailing_list ||= MailingList.find(Group.root.sac_magazine_mailing_list_id)
      end

      def active_roles_of_type(type)
        active_roles.select { |r| r.is_a?(type) }
      end

      def active_roles
        @active_roles ||= active_roles_of(person)
      end

      def active_roles_of(person)
        person.roles.select { |r| r.active_period.cover?(date) }
      end

      def active_main_membership_role?(person)
        active_roles_of(person).any? { |r| r.is_a?(MAIN_MEMBERSHIP_ROLE) }
      end
    end
  end
end
