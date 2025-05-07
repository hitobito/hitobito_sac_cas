# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require_relative "../command"
require_relative "../helpers/cli_menu"

module TTY
  module MailingLists
    class CreateSektionsbulletin
      prepend TTY::Command

      include Rails.application.routes.url_helpers

      self.description = "Create Sektionsbulletin"

      OPTIONS = [
        SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY,
        SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY
      ]

      attr_reader :group

      def initialize
        @group = ask_for_group
        puts green "Found #{group.class.name} #{group}"
      end

      def run
        list_existing_bulletins

        loop do
          if all_bulletin_lists_exist?
            puts info "All possible bulletin types exist for #{group}."
            break
          end

          create_bulletin
        end
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

      def type_to_label(internal_key)
        (internal_key == SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY) ? "Paper" : "Digital"
      end

      def all_bulletin_lists_exist?
        OPTIONS & existing_lists_internal_keys == OPTIONS
      end

      def existing_lists_internal_keys
        group.mailing_lists.where.not(internal_key: nil).pluck(:internal_key)
      end

      def list_existing_bulletins
        puts "Existing bulletins for #{group}:"

        bulletins = group.mailing_lists.where(internal_key: OPTIONS)

        bulletins.each do |bulletin|
          puts "- #{bulletin.name} (#{bulletin.internal_key})"
        end
        puts info "No existing bulletins found." if bulletins.empty?
      end

      def create_bulletin
        missing_bulletin_types = OPTIONS - existing_lists_internal_keys
        options = missing_bulletin_types.map do |type|
          label = type_to_label(type)
          key = label.downcase[0]
          [key, {description: label, action: -> { send(:"setup_bulletin_#{label.downcase}") }}]
        end.to_h

        CliMenu.new(menu_actions: options, prompt: "Which bulletin do you want to create?").run
      end

      def setup_bulletin_digital
        internal_key = SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY
        name = "Sektionsbulletin digital"
        setup_mailing_list(internal_key, name, "configured", "opt_in")
      end

      def setup_bulletin_paper
        internal_key = SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY
        name = "Sektionsbulletin physisch"
        setup_mailing_list(internal_key, name, "configured", "opt_out", filter_chain)
      end

      def filter_chain
        {"invoice_receiver" =>
           {"stammsektion" => "true", "zusatzsektion" => "true", "group_id" => group.id.to_s}}
      end

      def setup_mailing_list(internal_key, name, subscribable_for, mode, filter_chain = {})
        group.mailing_lists.create!(
          internal_key:,
          name:,
          filter_chain:,
          subscribable_for:,
          subscribable_mode: mode,
          subscriptions: [
            Subscription.new(
              subscriber: group,
              role_types: [
                Group::SektionsMitglieder::Mitglied,
                Group::SektionsMitglieder::MitgliedZusatzsektion
              ]
            )
          ]
        )
        puts success "Created #{name} (#{internal_key}) for #{group}."
      end
    end
  end
end
