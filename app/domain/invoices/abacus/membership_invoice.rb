# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    class MembershipInvoice
      MEMBERSHIP_CARD_FIELD_INDEX = 11

      # member is an Invoices::SacMembership::Member object
      attr_reader :member, :memberships, :new_entry

      delegate :context, to: :member
      delegate :date, :sac, :config, to: :context

      def initialize(member, memberships, new_entry: false)
        @member = member
        @memberships = memberships
        @new_entry = new_entry
      end

      def positions
        @positions ||=
          I18n.with_locale(member.language) do
            Invoices::SacMemberships::PositionGenerator
              .new(member)
              .generate(memberships, new_entry: new_entry)
              .map(&:to_abacus_invoice_position)
          end
      end

      def total
        positions.sum(&:amount)
      end

      def additional_user_fields
        fields = {}
        fields[:user_field4] = config.service_fee.to_f if invoice?
        compose_membership_card_user_fields(fields)
        fields
      end

      # Whether to create/send an invoice or not.
      # No invoices are created for members that appear on another invoice,
      # e.g. family members without additional memberships.
      def invoice?
        member.sac_family_main_person? || memberships.any? { |m| !m.family? }
      end

      def membership_cards?
        !!main_membership &&
          member.paying_person?(main_membership.beitragskategorie)
      end

      private

      def compose_membership_card_user_fields(fields)
        return unless membership_cards?

        index = MEMBERSHIP_CARD_FIELD_INDEX
        fields[:"user_field#{index}"] = membership_card_data(member.person)
        member.family_members.each do |member|
          index += 1
          fields[:"user_field#{index}"] = membership_card_data(member)
        end
      end

      def main_membership
        return @main_membership if defined?(@main_membership)

        @main_membership = memberships.find(&:main)
      end

      def membership_card_data(person)
        # limit strings according to Abacus field length (120)
        [
          person.id,
          person.last_name.to_s.delete(";")[0, 50],
          person.first_name.to_s.delete(";")[0, 30],
          person.membership_verify_token
        ].join(";")
      end
    end
  end
end
