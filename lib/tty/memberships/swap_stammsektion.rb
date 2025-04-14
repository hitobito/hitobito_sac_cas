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
        puts green "Found #{affected_people.map { |p| "#{p} (#{p.id})" }.join(", ")}"
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

          unless person.sac_membership.zusatzsektion_roles.present?
            puts error "Person #{person_id} has no Zusatzsektion roles. Please give me a valid ID."
            next # ask again
          end

          return person
        end
      end

      def ask_for_new_stammsektion
        if family?
          puts yellow "This is a family, so only Zusatzsektion family memberships are available."
          compatible_options = person.sac_membership.zusatzsektion_roles.select(&:family?)
        else
          compatible_options = person.sac_membership.zusatzsektion_roles
        end

        menu_actions = compatible_options.each_with_object({}).with_index do |(role, hash), index|
          hash[(index + 1).to_s] = {description: role.group.layer_group.to_s, action: role}
        end

        menu_actions["p"] = {
          description: "Open person profile in browser",
          action: lambda do
            open_person_history
            ask_for_new_stammsektion
          end,
          style: :dim
        }

        CliMenu.new(menu_actions: menu_actions, prompt: "Choose the new Stammsektion").run
      end

      def family? = person.sac_membership.family?

      def affected_people
        family? ? person.household.people : [person]
      end

      def swap!
        puts " -> Swapping #{old_stammsektion_role.group.layer_group} <-> #{old_zusatzsektion_role.group.layer_group}"

        Role.transaction do
          affected_people.each(&method(:swap_for_person))
        end

        puts green "Swapping completed"
      end

      def swap_for_person(p)
        person_old_stammsektion_role = p.roles.find_by(type: old_stammsektion_role.class.sti_name, group_id: old_stammsektion_role.group_id)
        person_old_zusatzsektion_role = p.roles.find_by(type: old_zusatzsektion_role.class.sti_name, group_id: old_zusatzsektion_role.group_id)

        original_stammsektion_end_on = old_stammsektion_role.end_on
        original_zusatzsektion_end_on = old_zusatzsektion_role.end_on

        destroy_ignore_household_and_dependents(person_old_zusatzsektion_role)
        destroy_ignore_household_and_dependents(person_old_stammsektion_role)

        Group::SektionsMitglieder::Mitglied.create!(
          person: p,
          group: person_old_zusatzsektion_role.group,
          start_on: Date.current,
          end_on: original_zusatzsektion_end_on,
          beitragskategorie: person_old_zusatzsektion_role.beitragskategorie
        )

        Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
          person: p,
          group: person_old_stammsektion_role.group,
          start_on: Date.current,
          end_on: original_stammsektion_end_on,
          beitragskategorie: person_old_stammsektion_role.beitragskategorie
        )
      end

      def confirm?
        puts "The Stammsektion will be changed from #{yellow old_stammsektion_role.group.layer_group} to #{green old_zusatzsektion_role.group.layer_group}"
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
            open_person_history
          else
            puts error "Invalid choice. Please enter 'y' or 'n'."
          end
        end
      end

      def open_person_history
        url = history_group_person_url(
          host: "portal.sac-cas.ch",
          protocol: "https",
          group_id: old_stammsektion_role.group,
          id: person
        )
        system("xdg-open", url, out: "/dev/null")
      end

      def destroy_ignore_household_and_dependents(role)
        role.skip_destroy_dependent_roles = true
        role.skip_destroy_household = true if role.respond_to?(:skip_destroy_household)
        role.destroy!
      end
    end
  end
end
