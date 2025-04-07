# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require_relative "../helpers/format"
require_relative "../helpers/cli_menu"
require_relative "../helpers/paper_trailed"

module TTY
  module Memberships
    class SwapStammsektion
      include Rails.application.routes.url_helpers
      include TTY::Helpers::Format
      include TTY::Helpers::PaperTrailed

      attr_reader :person, :old_stammsektion_role, :old_zusatzsektion_role

      def initialize
        puts light_yellow "Swap Stammsektion"
        @person = ask_for_person
        @old_stammsektion_role = person.sac_membership.stammsektion_role
        @old_zusatzsektion_role = ask_for_new_stammsektion
      end

      def run
        set_papertrail_metadata
        swap! if confirm?
      end

      private

      def ask_for_person
        loop do
          print "Please enter the ID of the person you want to swap: "
          person_id = gets.chomp

          unless /\A\d+\z/.match?(person_id)
            puts error "Invalid ID. Please enter a number."
            next # ask again
          end

          person = Person.find_by(id: person_id)

          unless person
            puts error "Person #{person_id} not found. Please give me a valid ID."
            next # ask again
          end

          unless person.sac_membership.active?
            puts error "Person #{person_id} is not an active member. Please give me a valid ID."
            next # ask again
          end

          if person.sac_membership.stammsektion_role.family?
            puts error "Family memberships are not supported. Please give me a valid ID."
            next # ask again
          end

          unless person.sac_membership.zusatzsektion_roles.present?
            puts error "Person #{person_id} has no Zusatzsektion roles. Please give me a valid ID."
            next # ask again
          end

          puts "Found #{person} with ID #{person.id}"
          return person
        end
      end

      def ask_for_new_stammsektion
        menu_actions = person.sac_membership.zusatzsektion_roles.each_with_object({}).with_index do |(role, hash), index|
          hash[(index + 1).to_s] = {description: role.group.layer_group.to_s, action: role}
        end
        CliMenu.new(menu_actions: menu_actions, prompt: "Choose the new Stammsektion").run
      end

      def swap!
        puts " -> Swapping #{old_stammsektion_role.group.layer_group} <-> #{old_zusatzsektion_role.group.layer_group}"

        Role.transaction do
          original_stammsektion_end_on = old_stammsektion_role.end_on
          original_zusatzsektion_end_on = old_zusatzsektion_role.end_on

          old_zusatzsektion_role.destroy!
          old_stammsektion_role.destroy!
          binding.pry
          Group::SektionsMitglieder::Mitglied.create!(
            person:,
            group: old_zusatzsektion_role.group,
            start_on: Date.current,
            end_on: original_zusatzsektion_end_on,
            beitragskategorie: old_zusatzsektion_role.beitragskategorie
          )

          Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
            person:,
            group: old_stammsektion_role.group,
            start_on: Date.current,
            end_on: original_stammsektion_end_on,
            beitragskategorie: old_stammsektion_role.beitragskategorie
          )
        end

        puts " -> Swapping done"
      end

      def confirm?
        puts "The Stammsektion will be changed from #{yellow old_stammsektion_role.group.layer_group} to #{green old_zusatzsektion_role.group.layer_group} for person #{person.id} #{person}"
        puts "#{old_zusatzsektion_role.group.layer_group} will become a Zusatzsektion"
        print yellow "Do you want to execute the swap? (y/n): "

        loop do
          choice = $stdin.getch.tap { puts } # Read a single character and print a newline

          case choice
          when "y"
            puts "Starting swap..."
            return true
          when "n"
            puts light_red "Swap canceled."
            return false
          when "p"
            puts "Opening person profile in browser..."
            url = history_group_person_url(host: "portal.sac-cas.ch", protocol: "https", group_id: old_stammsektion_role.group, id: person)
            system("xdg-open", url)
          else
            puts error "Invalid choice. Please enter 'y' or 'n'."
          end
        end
      end
    end
  end
end
