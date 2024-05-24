# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class Person
      attr_reader :model, :context
      attr_writer :sac_magazine_mailing_list

      delegate :id, :to_s, :sac_family_main_person?, to: :model
      delegate :date, to: :context

      # Person model
      def initialize(model, context)
        @model = model
        @context = context
      end

      def age
        @age ||= model.years(Date.new(date.year, 12, 31))
      end

      def membership_years
        # person must have been loaded with .with_membership_years(date)
        model.membership_years
      end

      def main_membership_role
        @main_membership_role ||= active_roles_of_type(Group::SektionsMitglieder::Mitglied).first
      end

      def additional_membership_roles
        @additional_membership_roles ||=
          active_roles_of_type(Group::SektionsMitglieder::MitgliedZusatzsektion)
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
        !model.swiss?
      end

      def sac_magazine?
        return @sac_magazine if defined?(@sac_magazine)

        @sac_magazine = sac_magazine_mailing_list.subscribed?(model)
      end

      private

      def sac_magazine_mailing_list
        @sac_magazine_mailing_list ||= MailingList.find(Group.root.sac_magazin_mailing_list_id)
      end

      def active_roles_of_type(type)
        active_roles.select { |r| r.is_a?(type) }
      end

      def active_roles
        @active_roles ||= model.roles.select { |r| r.active_period.cover?(date) }
      end
    end
  end
end
