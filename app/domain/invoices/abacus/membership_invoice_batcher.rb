# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    # This class is currently used for POC purposes.
    # Parts may be re-used in production but the final process may be different.
    # TODO: implement transmit people to handle updates
    # TODO: handle errors in parts. Map request parts to response parts (for subject assocs)?
    class MembershipInvoiceBatcher
      attr_reader :date

      def initialize(date, client: nil)
        @date = date
        @client = client
      end

      # rubocop:disable Layout/LineLength
      # create invoices for people with abacus_subject_key:
      # date = Time.zone.today; RestClient.log = STDOUT; ms = nil; ex = nil; response = nil; count = 50
      # reload!; people = Person.joins(:roles).where(roles: { type: Group::SektionsMitglieder::Mitglied.sti_name }).where.not(people: { abacus_subject_key: nil }).limit(count).with_membership_years('people.*', date).includes(:roles).order_by_name;
      # batch = Invoices::Abacus::MembershipInvoiceBatcher.new(date)
      # begin; ms = Benchmark.ms { response = batch.create_invoices(people) }; rescue RestClient::Exception => e; ex = e; end
      # or create new people:
      # locations = Location.all.to_a
      # people = 100.times.map { loc = locations.sample; p = Person.create!(last_name: Faker::Name.last_name, first_name: Faker::Name.first_name, zip_code: loc.zip_code, town: loc.name, street: Faker::Address.street_name, housenumber: rand(200), birthday: (rand(90*365) + (7 * 365)).days.ago); Group::SektionsMitglieder::Mitglied.create!(person: p, group_id: 26, created_at: rand(800).months.ago, delete_on: '2024-12-31'); p }
      # people = Person.where(id: people.map(&:id)).with_membership_years('people.*', date).includes(:roles).order_by_name, date)
      # batch = Invoices::Abacus::MembershipInvoiceBatcher.new(date)
      # begin; ms = Benchmark.ms { response = batch.create_people(people) }; rescue RestClient::Exception => e; ex = e; end
      # rubocop:enable Layout/LineLength
      def create_people(people)
        subjects = people.map { |person| Subject.new(person) }
        subject_interface.create_batch(subjects)
      end

      def create_invoices(people)
        sales_orders = []
        ms = Benchmark.ms do
          invoices = membership_invoices(people)
          sales_orders = invoices.map(&:sales_order)
        end
        Rails.logger.debug { "Creating invoices: #{ms}ms" }
        sales_order_interface.create_batch(sales_orders)
      end

      # Test with batch size of 25, in 4 parallel threads
      def create_parallel_invoices(people)
        slices = people.each_slice(25).to_a
        Parallel.map(slices, in_threads: 4) do |slice|
          ActiveRecord::Base.connection_pool.with_connection do
            create_invoices(slice)
          end
        end
      end

      private

      def membership_invoices(people)
        people.filter_map do |person|
          member = Invoices::SacMemberships::Member.new(person, context)
          if member.main_membership_role
            MembershipInvoice.new(member, member.main_membership_role)
          end
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
