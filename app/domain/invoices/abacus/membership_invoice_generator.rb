# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    class MembershipInvoiceGenerator
      attr_reader :person, :role, :date

      def initialize(person, date: nil, role: nil, client: nil)
        @person = person
        @date = date || Time.zone.today
        @role = role || current_role
        @client = client
      end

      def generate
        subject_interface.transmit(subject) &&
          sales_order_interface.create(sales_order)
      rescue RestClient::Exception => e
        @membership_invoice&.handle_abacus_exception(e)
        raise e
      end

      def invoice
        membership_invoice.invoice
      end

      # for machines
      def errors
        subject.errors.merge(sales_order.errors)
      end

      # for humans
      def error_messages
        subject.error_messages + sales_order.error_messages
      end

      private

      def member
        @member ||= SacMemberships::Member.new(person, context)
      end

      def membership_invoice
        @membership_invoice ||= MembershipInvoice.new(member, role)
      end

      def subject
        @subject ||= Subject.new(person)
      end

      def sales_order
        @sales_order ||= membership_invoice.sales_order
      end

      def current_role
        if member.new_entry_role
          member.new_entry_role
        elsif member.new_additional_section_membership_roles.present?
          member.new_additional_section_membership_roles.first
        else
          member.main_membership_role
        end
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
