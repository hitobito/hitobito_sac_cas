# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas


module TTY
  module MailingLists
    class CleanupPilatusBulletins
      prepend TTY::Command
      attr_reader :pilatus, :list, :list_people_ids, :people_ids

      BULLETIN_PHYSISCH = "Sektionsbulletin physisch"
      self.description = "Cleanup Pilatus Sektionsbulletin HIT-1326"

      def initialize
        @pilatus = Group::Sektion.find_by!(name: "SAC Pilatus")
        @list = @pilatus.mailing_lists.find_by!(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY)
        @list_people_ids = list.people.pluck(:id)
        @people_ids = load_currently_subscribed_people_ids
      end

      def run(dry_run: false)
        puts "People total: #{people_ids.size}"
        puts "People total uniq: #{people_ids.uniq.size}"

        MailingList.transaction do
          add_deep_flag

          create_excluding_subscriptions
          destroy_obsolete_excluding_subscriptions

          updated_people_ids = list.people.pluck(:id)
          puts "People total: #{updated_people_ids.size}"
          puts "People total uniq: #{updated_people_ids.uniq.size}"
          puts "unsubscribed: #{people_ids - updated_people_ids}, subscribed: #{updated_people_ids - people_ids}"

          destroy_digital_bulletin!
          ortsgruppen_lists.each(&:destroy!)

          fail "dry run" if dry_run
        end
      end

      def destroy_digital_bulletin!
        @pilatus.mailing_lists.find_by!(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY).destroy!
      end

      def add_deep_flag
        filter = list.filter_chain.filters.find {
          _1.is_a?(Person::Filter::InvoiceReceiver)
        }
        filter.args[:deep] = true
        list.save!
      end

      def ortsgruppen_lists
        MailingList.joins(:group)
          .where(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY)
          .where(groups: {id: pilatus.children.where(type: "Group::Ortsgruppe").select(:id)})
      end

      def destroy_obsolete_excluding_subscriptions
        updated_people_ids = list.people.pluck(:id)
        obsolete_subscriber_ids = list_people_ids - updated_people_ids
        list.subscriptions.people.excluded.where(subscriber_id: obsolete_subscriber_ids).destroy_all
      end

      def create_excluding_subscriptions
        pilatus_subscriber_ids_from_roles = list.people.pluck(:id) - list.subscriptions.people.pluck(:subscriber_id)
        ortsgruppen_lists.each do |list|
          excluded_people_ids = list.subscriptions.people.excluded.pluck(:subscriber_id) & pilatus_subscriber_ids_from_roles
          puts "Excluding #{excluded_people_ids.size} from #{list.group.name}"

          excluded_people_ids.each do |subscriber_id|
            Subscription.find_or_create_by(
              mailing_list_id: list.id,
              excluded: true,
              subscriber_type: "Person",
              subscriber_id:
            )
          end
        end
      end

      def load_currently_subscribed_people_ids
        list_people_ids + ortsgruppen_lists.flat_map { |l| l.people.pluck(:id) }
      end
    end
  end
end
