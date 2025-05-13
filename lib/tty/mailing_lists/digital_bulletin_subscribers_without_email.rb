# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module MailingLists
    class DigitalBulletinSubscribersWithoutEmail
      prepend TTY::Command

      self.description = "List digital bulletin subscribers without email"

      def run
        puts info "Writing to #{filename} ..."

        with_file do |file|
          data = []

          subscriber_without_email.find_each do |person|
            digital_bulletin_subs = person.subscriptions.select do |subscription|
              subscription.mailing_list.internal_key == SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY
            end
            section_ids = digital_bulletin_subs.map { |sub| sub.mailing_list.group_id }

            data << [person.id] + section_ids
          end

          rows_count = data.map(&:size).max
          header = ["Person ID"] + (1..(rows_count - 1)).map { |i| "Section ID #{i}" }

          file.puts header.join(",")
          data.each { file.puts _1.join(",") }
        end
        puts info "Done"
      end

      private

      def filename
        @filename ||= begin
          timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
          "/tmp/digital_bulletin_without_email-#{timestamp}.csv"
        end
      end

      def with_file
        File.open(filename, "w") do |file|
          yield file
        end
      end

      def subscriber_without_email
        Person.where(email: nil).joins(subscriptions: :mailing_list)
          .where(mailing_lists: {internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY})
          .order(:id)
          .includes(subscriptions: :mailing_list)
          .distinct
      end
    end
  end
end
