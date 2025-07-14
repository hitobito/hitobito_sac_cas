# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module MailingLists
    class CleanupPaperBulletinSubscribersKirchberg
      prepend TTY::Command

      self.description = "Fix paper subscribers for Kirchberg HIT-966"

      BULLETIN_TYPES = [
        SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY,
        SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY
      ]

      attr_reader :sektion, :bulletin_paper, :bulletin_digital

      def initialize
        @sektion = Group::Sektion.find(3200)
        @bulletin_paper = sektion.mailing_lists.find_by!(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY)
        @bulletin_digital = sektion.mailing_lists.find_by!(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY)
      end

      def run
        if confirm?
          puts info "Collecting subscriber stats of all sections..."
          before_stats = subscribers_stats
          original_paper_subscribers = ::MailingLists::Subscribers.new(bulletin_paper).people
          surplus_subscribers = original_paper_subscribers.select { intended_subscriber_ids.exclude?(_1.id) }

          puts info "Removing surplus subscribers from paper list..."
          surplus_subscribers.each_with_index do |surplus_person, index|
            print "\rPerson #{index + 1} of #{surplus_subscribers.size}"
            Person::Subscriptions.new(surplus_person).destroy(bulletin_paper)
          end
          puts

          puts info "Subscribing intended subscribers to paper list..."
          intended_subscriber_ids.each_with_index do |subscriber_id, index|
            print "\rPerson #{index + 1} of #{intended_subscriber_ids.size}"
            person = Person.find(subscriber_id)
            Person::Subscriptions.new(person).create(bulletin_paper)
          end
          puts

          print_stats "Before migration", before_stats
          print_stats "After migration", subscribers_stats
        end
        true
      end

      private

      def intended_subscriber_ids
        [
          339718,
          175002,
          111663,
          115777,
          129506,
          131562,
          131566,
          131581,
          131591,
          131599,
          131614,
          131616,
          131636,
          146639,
          147515,
          154719,
          168323,
          174223,
          180766,
          198041,
          221160,
          223830,
          274471,
          281640,
          288418,
          311702,
          328603
        ]
      end

      def confirm?
        CliMenu.new(prompt: "Do you want to execute the paper subscriber cleanup?", menu_actions: {
          "y" => {description: "Yes", action: true},
          "n" => {description: "No", action: false}
        }).run
      end

      def subscribers_stats
        [
          "  * Paper people: #{paper_people_count}",
          "  * Digital people: #{digital_people_count}"
        ]
      end

      def paper_people_count = ::MailingLists::Subscribers.new(bulletin_paper).people.to_a.size

      def digital_people_count = ::MailingLists::Subscribers.new(bulletin_digital).people.to_a.size

      def print_stats(title, stats)
        puts info title
        stats.each { puts _1 }
      end
    end
  end
end
