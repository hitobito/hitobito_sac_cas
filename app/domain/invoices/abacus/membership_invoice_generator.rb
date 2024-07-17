# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    # This class is currently used for POC purposes.
    # Parts may be re-used in production but the final process may be different.
    class MembershipInvoiceGenerator
      attr_reader :person, :memberships, :date, :new_entry, :discount, :send_on

      def initialize(person, memberships = nil, invoice: nil, date: nil, new_entry: false, discount: nil, send_on: nil, client: nil)
        @person = person
        @invoice = invoice
        @date = date || Time.zone.today
        @new_entry = new_entry
        @discount = discount
        @send_on = send_on || @date
        @client = client
        @memberships = memberships || current_memberships
      end

      def generate
        return false unless membership_invoice.invoice?

        invoice.update!(total: membership_invoice.total)
        subject_interface.transmit(subject) &&
          sales_order_interface.create(sales_order)
      rescue RestClient::Exception => e
        handle_abacus_exception(e)
        raise e
      end

      def invoice # rubocop:disable Metrics/MethodLength
        @invoice ||=
          ExternalInvoice::SacMembership.create!(
            person: member.person,
            year: date.year,
            state: :draft,
            total: membership_invoice.total,
            issued_at: date,
            sent_at: send_on || date,
            # also see comment in ExternalInvoice::SacMembership
            link: invoice_section
          )
      end

      # for machines
      def errors
        subject.errors.merge(@sales_order&.errors || {})
      end

      # for humans
      def error_messages
        subject.error_messages + (@sales_order&.error_messages || [])
      end

      private

      def handle_abacus_exception(exception)
        invoice.update!(state: :error)
        invoice.hitobito_log_entries.create!(
          message: exception.message,
          level: :error,
          category: "rechnungen"
        )
      end

      def member
        @member ||= SacMemberships::Member.new(person, context)
      end

      def membership_invoice
        @membership_invoice ||= MembershipInvoice.new(
          member,
          memberships,
          new_entry: new_entry,
          discount: discount
        )
      end

      def subject
        @subject ||= Subject.new(person)
      end

      def sales_order
        @sales_order ||= SalesOrder.new(
          invoice,
          membership_invoice.positions,
          membership_invoice.additional_user_fields
        )
      end

      def current_memberships
        if member.new_entry_role
          @new_entry = true
          [member.membership_from_role(member.new_entry_role, main: true)]
        elsif member.new_additional_section_membership_roles.present?
          [member.membership_from_role(member.new_additional_section_membership_roles.first)]
        else
          member.active_memberships
        end
      end

      def invoice_section
        (memberships.find(&:main) || memberships.first).section
      end

      def context
        @context ||= Invoices::SacMemberships::Context.new(date)
      end

      def sales_order_interface
        @sales_order_interface ||= SalesOrderInterface.new(client)
      end

      def subject_interface
        @subject_interface ||= SubjectInterface.new(client)
      end

      def client
        @client ||= Client.new
      end
    end
  end
end
