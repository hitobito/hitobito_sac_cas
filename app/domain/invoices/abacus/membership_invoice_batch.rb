# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    # In batch requests, collect single requests and send them in one call.
    # Mimic behavior of single requests as emitted by MembershipInvoice class
    # by directly calling the abacus entity classes.
    # TODO: delete dev data again on abacus
    # TODO: try with 100 / 1000 invoices
    # TODO: tests
    # TODO: implement transmit people to handle updates
    # TODO: handle errors in parts. Map request parts to response parts (for subject assocs)?
    # TODO: refactor to reduce logic duplication single/batch
    class MembershipInvoiceBatch

      attr_reader :people, :date

      def initialize(people, date)
        @people = people
        @date = date
      end

      # date = Time.zone.today; RestClient.log = STDOUT; ms = nil; ex = nil;
      # reload!; people = Person.joins(:roles).where(roles: { type: Group::SektionsMitglieder::Mitglied.sti_name }).where(people: { abacus_subject_key: nil }).limit(10).with_membership_years('people.*', date).includes(:roles).order_by_name; batch = Invoices::Abacus::MembershipInvoiceBatch.new(people, date); nil
      # begin; ms = Benchmark.ms { response = batch.create_people }; rescue RestClient::Exception => e; ex = e; end
      # or
      # locations = Location.all.to_a
      # people = 100.times.map { loc = locations.sample; p = Person.create!(last_name: Faker::Name.last_name, first_name: Faker::Name.first_name, zip_code: loc.zip_code, town: loc.name, street: Faker::Address.street_name, housenumber: rand(200), birthday: (rand(90*365) + (7 * 365)).days.ago); Group::SektionsMitglieder::Mitglied.create!(person: p, group_id: 26, created_at: rand(800).months.ago, delete_on: '2024-12-31'); p }
      # batch = Invoices::Abacus::MembershipInvoiceBatch.new(Person.where(id: people.map(&:id)).with_membership_years('people.*', date).includes(:roles).order_by_name, date); nil
      # begin; ms = Benchmark.ms { response = batch.create_people }; rescue RestClient::Exception => e; ex = e; end
      def create_people
        batch_response = create_subjects
        assign_abacus_subject_keys(batch_response)
        create_subject_associations
      end

      def create_invoices
        batch_response = create_sales_orders
        assign_abacus_sales_order_keys(batch_response)
        trigger_sales_orders
      end

      private

      def create_subjects
        client.batch do
          membership_invoices.each do |invoice|
            invoice.abacus_person.create_subject_request
          end
        end
      end

      def assign_abacus_subject_keys(batch_response)
        membership_invoices.each_with_index do |invoice, index|
          part = batch_response.parts[index]
          invoice.abacus_person.assign_abacus_subject_key(part.json) if part&.created?
        end
      end

      def create_subject_associations
        client.batch do
          membership_invoices.each do |invoice|
            invoice.abacus_person.create_address
            invoice.abacus_person.create_communications
            invoice.abacus_person.create_customer
          end
        end
      end

      def create_sales_orders
        client.batch do
          ms = Benchmark.ms do
            membership_invoices.each do |invoice|
              invoice.create_abacus_sales_order_in_batch
            end
          end
          puts "Generating invoices took #{ms} ms"
        end
      end

      def assign_abacus_sales_order_keys(batch_response)
        membership_invoices.each_with_index do |invoice, index|
          part = batch_response.parts[index]
          invoice.abacus_sales_order.assign_abacus_sales_order_key(part.json) if part&.created?
        end
      end

      def trigger_sales_orders
        client.batch do
          membership_invoices.each do |invoice|
            invoice.abacus_sales_order.trigger_sales_order
          end
        end
      end

      def membership_invoices
        @membership_invoices ||= people.filter_map do |person|
          member = SacMemberships::Member.new(person, context)
          if member.main_membership_role
            MembershipInvoice.new(member, member.main_membership_role, client: client)
          end
        end
      end

      def context
        @context ||= Invoices::SacMemberships::Context.new(date)
      end

      def client
        @client ||= Abacus::Client.new
      end

    end
  end
end
