# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports
  class Nav1SubscriptionsImporter
    include LogCounts

    REPORT_HEADERS = [
      :navision_membership_number,
      :navision_name,
      :status,
      :warnings,
      :errors
    ]

    attr_reader :list_die_alpen_digital, :list_die_alpen_paper, :list_fundraising

    def initialize(output: $stdout)
      @output = output
      @source_file = CsvSource.new(:NAV1)
      @csv_report = CsvReport.new(:"nav1-3_subscriptions", REPORT_HEADERS, output:)
      @list_die_alpen_paper = MailingList
        .find_by!(internal_key: SacCas::MAILING_LIST_DIE_ALPEN_PAPER_INTERNAL_KEY)
      @list_die_alpen_digital = MailingList
        .find_by!(internal_key: SacCas::MAILING_LIST_DIE_ALPEN_DIGITAL_INTERNAL_KEY)
      @list_fundraising = MailingList
        .find_by!(internal_key: SacCas::MAILING_LIST_SPENDENAUFRUFE_INTERNAL_KEY)

      # warm up memoized data otherwise each thread will create a new one
      bulletin_list_paper_by_group_id
      bulletin_list_digital_by_group_id
      people_by_id
    end

    def create
      data = @source_file.rows

      @csv_report.log("The file contains #{data.size} rows.")

      # log_counts_delta(@csv_report,
      #   "Die Alpen Paper receiver" => -> { MailingLists::Subscribers.new(list_die_alpen_paper).people.size },
      #   "Die Alpen Digital receiver" => -> { MailingLists::Subscribers.new(list_die_alpen_digital).people.size },
      #   "Fundraising receiver count" => -> { MailingLists::Subscribers.new(list_fundraising).people.size },
      #   "Bulletin Paper receiver count" => -> { receiver_numbers_for_lists(bulletin_list_paper_by_group_id.values) },
      #   "Bulletin Digital receiver count" => -> { receiver_numbers_for_lists(bulletin_list_digital_by_group_id.values) }) do
      log_counts_delta(@csv_report,
        Subscription,
        "Die Alpen Paper subscription" => Subscription.where(subscriber_type: "Person", mailing_list_id: list_die_alpen_paper.id, excluded: false),
        "Die Alpen Paper exclusion" => Subscription.where(subscriber_type: "Person", mailing_list_id: list_die_alpen_paper.id, excluded: true),
        "Die Alpen Digital subscription" => Subscription.where(subscriber_type: "Person", mailing_list_id: list_die_alpen_digital.id, excluded: false),
        "Fundraising subscription" => Subscription.where(subscriber_type: "Person", mailing_list_id: list_fundraising.id, excluded: false),
        "Bulletin Paper subscriptions" => Subscription.joins(:mailing_list).where(subscriber_type: "Person", mailing_list: {internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY}, excluded: false),
        "Bulletin Paper exclusions" => Subscription.joins(:mailing_list).where(subscriber_type: "Person", mailing_list: {internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY}, excluded: true),
        "Bulletin Digital subscriptions" => Subscription.joins(:mailing_list).where(subscriber_type: "Person", mailing_list: {internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY}, excluded: false)) do
        progress = Progress.new(data.size, title: "NAV1 Subscriptions Import", output: @output)

        data.each do |row|
          # Parallel.map(data, in_threads: Etc.nprocessors) do |row|
          progress.step
          process_row(row)
        end
      end
      # end

      @csv_report.finalize
    end

    private

    def process_row(row)
      People::SubscriptionEntry.new(row, @csv_report, people_by_id, list_die_alpen_paper,
        list_die_alpen_digital, list_fundraising, bulletin_list_paper_by_group_id,
        bulletin_list_digital_by_group_id).create
    end

    def people_by_id
      @people ||= Person.select(:id).index_by(&:id)
    end

    def bulletin_list_paper_by_group_id
      @bulletin_list_paper_by_group_id ||= MailingList
        .where(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY)
        .index_by(&:group_id)
    end

    def bulletin_list_digital_by_group_id
      @bulletin_list_digital_by_group_id ||= MailingList
        .where(internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY)
        .index_by(&:group_id)
    end

    def receiver_numbers_for_lists(lists)
      lists.sum do |list|
        MailingLists::Subscribers.new(list).people.size
      end
    end
  end
end
