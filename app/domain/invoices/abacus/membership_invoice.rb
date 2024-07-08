# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    class MembershipInvoice
      MEMBERSHIP_CARD_FIELD_INDEX = 11
      INVOICE_KIND = :membership

      # member is an Invoices::SacMembership::Member object
      # role is an membership or new membership Role
      attr_reader :member, :role

      delegate :context, to: :member
      delegate :date, :sac, :config, to: :context

      class << self
        # Primarly used for testing purposes.
        # member is an Invoices::SacMembership::Member object
        # Role retrieval will usually happen outside of this class.
        def generate_current(member, client: nil)
          new(member, current_role(member), client: client).generate
        end

        def current_role(member)
          if member.new_entry_role
            member.new_entry_role
          elsif member.new_additional_section_membership_roles.present?
            member.new_additional_section_membership_roles.first
          else
            member.main_membership_role
          end
        end
      end

      def initialize(member, role, client: nil)
        @member = member
        @role = role
        @client = client
      end

      def generate
        return false unless abacus_person.transmit

        I18n.with_locale(member.language) do
          create_abacus_sales_order
          invoice.save!
        end
        true
      rescue => e
        @invoice&.destroy
        raise e
      end

      def invoice
        @invoice ||= Invoice.create!(
          recipient: member.person,
          group: sac,
          title: I18n.t("invoices.sac_memberships.title", year: date.year),
          total: positions.sum(&:invoice_amount),
          issued_at: date,
          sent_at: date,
          invoice_kind: INVOICE_KIND,
          sac_membership_year: date.year
        )
      end

      def errors
        abacus_person.errors.merge(abacus_sales_order.errors)
      end

      def error_messages
        abacus_person.errors.map do |attr, key|
          ActiveModel::Error.new(member.person, attr, key).full_message
        end
      end

      private

      def create_abacus_sales_order
        abacus_sales_order.create(
          positions.map(&:to_abacus_invoice_position),
          additional_user_fields: compose_additional_user_fields
        )
      end

      def positions
        @positions ||= Invoices::SacMemberships::PositionGenerator.new(member).generate(role)
      end

      def compose_additional_user_fields
        fields = {}
        fields[:user_field4] = config.service_fee.to_f if member.service_fee?(role)
        compose_membership_card_user_fields(fields)
        fields
      end

      def compose_membership_card_user_fields(fields)
        return unless member.membership_cards?(role)

        index = MEMBERSHIP_CARD_FIELD_INDEX
        fields[:"user_field#{index}"] = membership_card_data(member.person)
        member.family_members.each do |member|
          index += 1
          fields[:"user_field#{index}"] = membership_card_data(member)
        end
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

      def abacus_person
        @abacus_person ||= Abacus::Person.new(member.person, client: client)
      end

      def abacus_sales_order
        @abacus_sales_order ||= Abacus::SalesOrder.new(invoice, client: client)
      end

      def client
        @client ||= Abacus::Client.new
      end
    end
  end
end
