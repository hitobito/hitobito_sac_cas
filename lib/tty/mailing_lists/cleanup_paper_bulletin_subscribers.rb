# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module MailingLists
    class CleanupPaperBulletinSubscribers
      prepend TTY::Command

      self.description = "Remove digital bulletin subscribers from paper bulletin"

      BULLETIN_TYPES = [
        SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY,
        SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY
      ]

      class PaperCleaner
        include TTY::Helpers::Format

        attr_reader :group, :log_prefix, :bulletin_paper, :bulletin_digital

        def initialize(group, log_prefix)
          @group = group
          @log_prefix = log_prefix
          @bulletin_paper = bulletin_for(SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY)
          @bulletin_digital = bulletin_for(SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY)
        end

        def run
          return unless ensure_all_bulletin_lists_exist

          unsubscribe_from_paper
        end

        private

        def log(message)
          print "\r#{log_prefix}#{message}"
        end

        def bulletin_for(internal_key)
          group.mailing_lists.to_a
            .find { _1.internal_key == internal_key }
        end

        def ensure_all_bulletin_lists_exist
          unless bulletin_paper
            log(warning("Bulletin Paper not found, skipping"))
            return false
          end
          unless bulletin_digital
            log(warning("Bulletin Digital not found, skipping"))
            return false
          end

          true
        end

        def unsubscribe_from_paper
          surplus_people = digital_people & paper_people
          return log(gray("Nothing to do...")) if surplus_people.empty?

          surplus_people.each_with_index do |surplus_person, index|
            next unless surplus_person.email.present?

            log "Removing person #{index + 1} of #{surplus_people.size} from paper list"
            Person::Subscriptions.new(surplus_person).destroy(bulletin_paper)
          end
        end

        def digital_people = ::MailingLists::Subscribers.new(bulletin_digital).people

        def paper_people = ::MailingLists::Subscribers.new(bulletin_paper).people
      end

      def run
        if confirm?
          puts info "Collecting subscriber stats of all sections..."
          before_stats = subscribers_stats
          print_stats "Before migration", before_stats

          all_sections.each_with_index do |section, index|
            msg = "#{index + 1}) #{section}: "
            PaperCleaner.new(section, msg).run
            puts
          end

          print_stats "Before migration", before_stats
          print_stats "After migration", subscribers_stats
        end
        true
      end

      private

      def all_sections
        Group
          .where(type: [Group::Sektion.sti_name, Group::Ortsgruppe.sti_name])
          .includes(:mailing_lists)
          .sort_by { _1.sorting_name }
      end

      def confirm?
        CliMenu.new(prompt: "Do you want to execute the paper subscriber cleanup?", menu_actions: {
          "y" => {description: "Yes, undo the termination", action: true},
          "n" => {description: "No, do not undo the termination", action: false}
        }).run
      end

      def subscribers_stats
        [
          "  * Paper people: #{paper_people_count}",
          "  * Digital people: #{digital_people_count}"
        ]
      end

      def paper_lists
        MailingList.where(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY)
      end

      def paper_people_count = paper_lists.sum { |l| ::MailingLists::Subscribers.new(l).people.to_a.size }

      def digital_lists
        MailingList.where(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY)
      end

      def digital_people_count = digital_lists.sum { |l| ::MailingLists::Subscribers.new(l).people.to_a.size }

      def print_stats(title, stats)
        puts info title
        stats.each { puts _1 }
      end
    end
  end
end
