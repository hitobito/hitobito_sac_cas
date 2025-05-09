# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/Output, Rails/Exit

module TTY
  class ManageMailingLists
    prepend TTY::Command
    include Helpers::Format

    self.description = "Manage mailing lists"

    MENU_ACTIONS = {
      "h" => {
        description: "Print 'hello world'",
        action: -> { puts [red("hello"), green("world")].join(" ") }
      },
      "1" => TTY::MailingLists::CreateSektionsbulletin,
      "2" => TTY::MailingLists::MigratePaperBulletinToDigital
    }.freeze

    def run
      loop do
        break unless CliMenu.new(menu_actions: MENU_ACTIONS).run
      end
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
        light_cyan("Mailing Lists Management ") +
        light_yellow("CLI!")
    end

    def print_byebye
      puts light_yellow "\nHave a great day, happy to assist you next time!"
    end
  end
end

# rubocop:enable Rails/Output, Rails/Exit
