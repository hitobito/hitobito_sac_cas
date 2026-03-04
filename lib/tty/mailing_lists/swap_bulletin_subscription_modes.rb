# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module MailingLists
    class SwapBulletinSubscriptionModes
      prepend TTY::Command

      self.description = "Swaps subscriptions modes, see HIT-1448"

      class List
        attr_reader :section, :kind, :list

        delegate :id, :destroyed?, :update!, :destroy!, :people, to: :list

        def initialize(section, kind)
          @section = section
          @kind = kind
          @list = find_list(section, kind)

          read_people_ids
        end

        def export(suffix)
          filename = "#{list.id}-people-#{suffix}.csv"
          if MailingList.where(id: list.id).exists?
            Export::SubscriptionsJob.new(:csv, Person.root.id, list.id,
              {filename: filename}).perform
          end
        end

        def subscriptions = list.subscriptions.people

        def read_people_ids = list.people.map(&:id)

        def people_ids = @people_ids ||= read_people_ids

        def subscriptions_counts
          @subscriptions_counts ||=
            subscriptions.group(:excluded).count
              .transform_keys { |key| key ? :excluding : :including }
        end

        def to_s(refresh = false)
          @people_ids = nil if refresh
          @subscriptions_counts = nil if refresh

          list_info = "#{list.group}(#{list.id}, #{kind}, #{list.subscribable_mode}"
          "#{list_info}): #{people_ids.count} #{subscriptions_counts}"
        end

        private

        def find_list(section, kind)
          MailingList
            .joins(:group)
            .find_by(internal_key: "sektionsbulletin_#{kind}", groups: {name: section})
        end
      end

      def initialize(dry_run: false, export: false)
        @dry_run = dry_run
        @export = export
      end

      def run
        puts "dry_run: #{dry_run?}, export: #{export?}"
        migrate_bulletins("SAC Weissenstein")
        migrate_bulletins("SAC Pfannenstiel")
        migrate_bulletins("SAC Kirchberg") do |paper, digital|
          digital.subscriptions.excluded.where(subscriber_id: paper.people_ids).destroy_all
          paper.destroy!
        end
      end

      private

      def migrate_bulletins(section) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity
        paper = List.new(section, :paper)
        digital = List.new(section, :digital)

        print_details_about(digital, paper, state: :before)
        MailingList.transaction do
          digital.subscriptions.destroy_all
          paper.subscriptions.destroy_all

          digital.update!(subscribable_mode: :opt_out)
          paper.update!(subscribable_mode: :opt_in)

          digital_exclusions = digital.read_people_ids - digital.people_ids

          insert_subscription(digital, people_ids: digital_exclusions, excluded: true)
          insert_subscription(paper, people_ids: paper.people_ids, excluded: false)

          yield paper, digital if block_given?
          print_details_about(digital, paper, refresh: true, state: :after)
          raise ActiveRecord::Rollback if dry_run?
        end
      end

      def dry_run? = @dry_run

      def export? = @export

      def insert_subscription(list, people_ids:, excluded:)
        attrs = {subscriber_type: "Person", mailing_list_id: list.id, excluded:}
        rows = people_ids.map { |subscriber_id| attrs.merge(subscriber_id:) }
        Subscription.insert_all(rows)
      end

      def print_details_about(*lists, state: :before, refresh: false)
        lists.reject(&:destroyed?).each { |list|
          puts list.to_s(refresh)
          list.export(state) if export?
        }
      end
    end
  end
end
