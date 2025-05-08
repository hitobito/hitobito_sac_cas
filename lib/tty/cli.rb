# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "io/console"

module TTY
  class Cli
    include TTY::Helpers::Format

    MENU_ACTIONS = {
      "h" => {
        description: "Print 'hello world'",
        action: -> { puts [red("hello"), green("world")].join(" ") }
      },
      "1" => TTY::ManageMemberships,
      "2" => TTY::ManageMailingLists,
      "q" => {description: "Quit", action: -> { quit }, style: :dim}
    }.freeze

    def run
      trap_ctrl_c
      Helpers::SacLogo.new.print

      loop do
        print_welcome_message
        CliMenu.new(menu_actions: MENU_ACTIONS).run
      end
    ensure
      print_byebye
    end

    private

    def trap_ctrl_c
      Signal.trap("INT") do
        exit(1)
      end
    end

    def print_welcome_message
      puts bold(light_yellow("Welcome to the ")) +
        light_red("SAC ") +
        light_cyan("CLI") +
        light_yellow("!")
      puts
      puts error <<~WARN
        WARN"WARNING: these CLI commands are not covered by the test suite!!!"
                      Use at your own risk!"
      WARN
    end

    def print_byebye
      puts light_yellow "\nHave a great day, happy to assist you next time!"
    end

    def self.quit = Process.kill("INT", Process.pid)
  end
end

# rubocop:enable Rails/Output, Rails/Exit
