# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module MailingLists
    class MigratePaperBulletinToDigital
      prepend TTY::Command

      self.description = "Migrate subscribers of paper bulletin to digital"

      BULLETIN_TYPES = [
        SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY,
        SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY
      ]

      attr_reader :group, :bulletin_paper, :bulletin_digital

      def initialize
        @group = ask_for_group
        puts green "Found #{group.class.name} #{group}"
        @bulletin_paper = group.mailing_lists.find_by(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY)
        @bulletin_digital = group.mailing_lists.find_by(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY)
      end

      def run
        ensure_all_bulletin_lists_exist || return
        before_stats = subscribers_stats
        migrate_subscribers
        print_stats "Before migration", before_stats
        print_stats "After migration", subscribers_stats
        true
      end

      private

      def ask_for_group
        loop do
          print "Please enter the ID of the Sektion/Ortsgruppe: "
          group_id = gets.chomp

          unless /\A\d+\z/.match?(group_id)
            puts error "Invalid ID. Please enter a number."
            next # ask again
          end

          group = Group.where(type: [Group::Sektion.sti_name, Group::Ortsgruppe.sti_name])
            .find_by(id: group_id)

          unless group
            puts error "Sektion/Ortsgruppe #{group_id} not found. Please give me a valid ID."
            next # ask again
          end

          return group
        end
      end

      def ensure_all_bulletin_lists_exist
        puts info "Checking if all bulletin lists exist for #{group}..."
        puts error "Bulletin Paper not found." unless bulletin_paper
        puts error "Bulletin Digital not found." unless bulletin_digital

        bulletin_paper.present? && bulletin_digital.present?
      end

      def subscribers_stats
        [
          "  * Paper people: #{paper_people.to_a.size}",
          "  * Paper people with confirmed email: #{paper_people_confirmed_email.to_a.size}",
          "  * Paper subscriptions: #{paper_subscriptions.count}",
          "  * Digital people: #{digital_people.to_a.size}",
          "  * Digital subscriptions: #{digital_subscriptions.count}"
        ]
      end

      def paper_people = MailingLists::Subscribers.new(bulletin_paper).people

      def paper_people_confirmed_email
        MailingLists::Subscribers.new(bulletin_paper,
          Person.where.not(
            confirmed_at: nil, email: nil, last_sign_in_at: nil
          )).people
      end

      def paper_subscriptions = bulletin_paper.subscriptions.where(subscriber_type: "Person")

      def digital_people = MailingLists::Subscribers.new(bulletin_digital).people

      def digital_subscriptions = bulletin_digital.subscriptions.where(subscriber_type: "Person")

      def print_stats(title, stats)
        puts info title
        stats.each { puts _1 }
      end

      def migrate_subscribers
        subscribe_to_digital
        unsubscribe_from_paper
      end

      def subscribe_to_digital
        puts info "Subscribing paper people with confirmed email to digital list"
        current_paper_people = paper_people.to_a
        current_paper_people.each_with_index do |paper_person, index|
          print "\r"
          print "Subscribing person #{index + 1} of #{current_paper_people.size} to digital list"
          Person::Subscriptions.new(paper_person).create(bulletin_digital)
        end
        puts
      end

      def unsubscribe_from_paper
        puts info "Removing digitally subscribed people from paper list"
        current_digital_people = digital_people.to_a
        current_digital_people.each_with_index do |digital_person, index|
          print "\r"
          puts "Removing person #{index + 1} of #{current_digital_people.size} from paper list"
          Person::Subscriptions.new(digital_person).destroy(bulletin_paper)
        end
        puts
      end
    end
  end
end
