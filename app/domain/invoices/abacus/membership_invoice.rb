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
      # role is a membership or new membership Role
      attr_reader :member, :role

      delegate :context, to: :member
      delegate :date, :sac, :config, to: :context

      def initialize(member, role)
        @member = member
        @role = role
      end

      def invoice # rubocop:disable Metrics/MethodLength
        @invoice ||=
          I18n.with_locale(member.language) do
            Invoice.create!(
              recipient: member.person,
              group: sac,
              title: I18n.t("invoices.sac_memberships.title", year: date.year),
              total: positions.sum(&:amount),
              issued_at: date,
              sent_at: date,
              invoice_kind: INVOICE_KIND,
              sac_membership_year: date.year
            )
          end
      end

      def handle_abacus_exception(e)
        # TODO: set invoice state to error
        # @invoice&.update!(state: :error)
      end

      def sales_order
        @sales_order ||= SalesOrder.new(invoice, positions, compose_additional_user_fields)
      end

      def positions
        @positions ||=
          I18n.with_locale(member.language) do
            Invoices::SacMemberships::PositionGenerator
              .new(member)
              .generate(role)
              .map(&:to_abacus_invoice_position)
          end
      end

      private

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
    end
  end
end
