# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/Output, Rails/Exit

require "io/console"
require_relative "helpers/cli_menu"
require_relative "helpers/format"
require_relative "helpers/sac_logo"
require_relative "memberships/promote_neuanmeldung"
require_relative "memberships/swap_stammsektion"

module TTY
  class ManageMemberships
    include Helpers::Format
    extend Helpers::Format

    MENU_ACTIONS = {
      "p" => {
        description: "Promote Neuanmeldung to Membership " + gray("(Stammsektion or Zusatzsektion)"),
        action: -> { Memberships::PromoteNeuanmeldung.new.run }
      },
      "s" => {
        description: "Swap Stammsektion ",
        action: -> { Memberships::SwapStammsektion.new.run }
      }
    }.freeze

    def self.run = new.run

    def run
      trap_ctrl_c
      Helpers::SacLogo.new.print
      print_welcome_message

      loop do
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
        light_cyan("Membership Management ") +
        light_yellow("CLI!")
    end

    def print_byebye
      puts light_yellow "\nHave a great day, happy to assist you next time!"
    end
  end
end

# rubocop:enable Rails/Output, Rails/Exit
