# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports::People
  class SubscriptionEntry
    attr_reader :row, :csv_report, :people_by_id, :list_die_alpen_paper, :list_die_alpen_digital,
      :list_fundraising, :bulletin_list_paper_by_group_id, :bulletin_list_digital_by_group_id

    def initialize(row, csv_report, people_by_id, list_die_alpen_paper, list_die_alpen_digital,
      list_fundraising, bulletin_list_paper_by_group_id, bulletin_list_digital_by_group_id)
      @row = row
      @csv_report = csv_report
      @people_by_id = people_by_id
      @list_die_alpen_paper = list_die_alpen_paper
      @list_die_alpen_digital = list_die_alpen_digital
      @list_fundraising = list_fundraising
      @bulletin_list_paper_by_group_id = bulletin_list_paper_by_group_id
      @bulletin_list_digital_by_group_id = bulletin_list_digital_by_group_id
    end

    def create
      return report(row, error: "Person not found") unless person

      subscribe_fundraising
      subscribe_die_alpen
      subscribe_bulletin
    end

    def person_id = parse_id(row.navision_id)

    def bulletin_digital_opt_in_group_ids = parse_ids(row.opt_in_sektionsbulletin_digital)

    def bulletin_digital_opt_out_group_ids = parse_ids(row.opt_out_sektionsbulletin_digital)

    def bulletin_paper_opt_in_group_ids = parse_ids(row.opt_in_sektionsbulletin_physisch)

    def bulletin_paper_opt_out_group_ids = parse_ids(row.opt_out_sektionsbulletin_physisch)

    private

    def subscribe?(field)
      value = row.send(field)
      ["0", "1"].include?(value) || raise("Invalid value #{value.inspect} for #{field}")
      value == "1"
    end

    def already_subscribed?(list)
      MailingLists::Subscribers.new(list_die_alpen_paper, Person.where(id: person.id))
        .people.include?(person)
    end

    def subscribe(list)
      sub = Subscription.where(subscriber: person, mailing_list: list).first_or_initialize
      sub.update!(excluded: false)
    end

    def unsubscribe(list)
      sub = Subscription.where(subscriber: person, mailing_list: list).first_or_initialize
      sub.update!(excluded: true)
    end

    def subscribe_fundraising
      # fundraisig is opt-in, so simply subscribe if the field is set
      subscribe(list_fundraising) if subscribe?(:opt_in_fundraising)
    end

    def subscribe_die_alpen
      # die alpen digital is opt-in, so simply subscribe if the field is set
      subscribe(list_die_alpen_digital) if subscribe?(:opt_in_die_alpen_digital)

      # die alpen paper is opt-out, so we subscribe or unsubscribe depending on the field
      if subscribe?(:opt_in_die_alpen_physisch)
        subscribe(list_die_alpen_paper)
      else
        unsubscribe(list_die_alpen_paper)
      end
    end

    def process_bulletin_subscriptions(action, label, group_ids, lists_by_group_id)
      group_ids.each do |group_id|
        list = lists_by_group_id[group_id]
        next report(row, error: "List #{label} not found for group #{group_id}") unless list

        if block_given?
          send(action, list) if yield(list)
        else
          send(action, list)
        end
      end
    end

    def subscribe_bulletin
      # bulletin paper is opt-out.
      # Subscribe all sections in bulletin_paper_opt_in_group_ids,
      # and unsubscribe all sections in bulletin_paper_opt_out_group_ids.
      process_bulletin_subscriptions(
        :subscribe, "bulletin paper",
        bulletin_paper_opt_in_group_ids, bulletin_list_paper_by_group_id
      ) # { |list| !already_subscribed?(list) }
      process_bulletin_subscriptions(
        :unsubscribe, "bulletin paper",
        bulletin_paper_opt_out_group_ids, bulletin_list_paper_by_group_id
      ) # { |list| already_subscribed?(list) }

      # bulletin digital is opt-in. Subscribe all sections in bulletin_digital_opt_in_group_ids.
      # Unsubscribe is not necessary because it is opt-in.
      process_bulletin_subscriptions(
        :subscribe, "bulletin digital",
        bulletin_digital_opt_in_group_ids, bulletin_list_digital_by_group_id
      )
    end

    def person = people_by_id[person_id]

    def subscriptions = Person::Subscriptions.new(person)

    def parse_ids(string)
      string
        .presence
        &.split(";")
        &.map(&method(:parse_id)) || []
    end

    def parse_id(string)
      return nil if string.blank?
      Integer(string.gsub(/^0+/, ""))
    end

    def report(row, warning: nil, error: nil)
      csv_report.add_row({
        navision_membership_number: row.navision_id,
        navision_name: "#{row.first_name} #{row.last_name}",
        errors: error,
        warnings: warning,
        status: if error.present?
                  "error"
                else
                  warning.present? ? "warning" : "success"
                end
      })
    end
  end
end
