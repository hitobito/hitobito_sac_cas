# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/Output, Rails/Exit

require "io/console"
require_relative "helpers/format"
require_relative "helpers/sac_logo"
require_relative "memberships/promote_neuanmeldung"

module TTY
  class ManageMemberships
    include Helpers::Format
    extend Helpers::Format

    QUIT = Class.new(StandardError)

    MENU_ACTIONS = {
      "p" => {
        description: "Promote Neuanmeldung to Membership " + gray("(Stammsektion or Zusatzsektion)"),
        action: -> { Memberships::PromoteNeuanmeldung.new.run }
      },
      # Add more actions here as needed
      # { description: "Another Task", action: -> { AnotherTask.new.run } },
      "q" => {
        description: "Exit",
        action: -> { Process.kill("INT", Process.pid) } # send SIGINT to self to break the loop
      }
    }.freeze

    def self.run = new.run

    def run
      trap_ctrl_c
      Helpers::SacLogo.new.print
      print_welcome_message
      main_loop
      print_byebye
    end

    private

    def main_loop
      loop do
        print_main_menu
        print "\nPlease choose an option: "
        handle_choice(read_single_char)
      end
    end

    def trap_ctrl_c
      Signal.trap("INT") do
        print_byebye
        exit(1)
      end
    end

    def print_welcome_message
      puts bold(light_yellow("Welcome to the ")) +
        light_red("SAC ") +
        light_cyan("Membership Management ") +
        light_yellow("CLI!")
    end

    def print_byebye
      puts light_yellow "\nHave a great day, happy to assist you next time!"
    end

    def print_main_menu
      puts "\nHow can I help you today?"
      MENU_ACTIONS.each do |key, args|
        args in { description:, action: }
        puts "#{key}) #{description}"
      end
    end

    # Reads a single character from standard input
    def read_single_char
      $stdin.getch.tap do
        puts # Echo newline after getch
      end
    end

    # Handles the user's choice based on the mapping
    def handle_choice(choice)
      return puts red "Invalid choice '#{choice}'. Please try again." unless MENU_ACTIONS.key?(choice)

      MENU_ACTIONS[choice] in { description:, action: }
      action.call # Execute the action associated with the choice
    end
  end
end

# rubocop:enable Rails/Output, Rails/Exit
