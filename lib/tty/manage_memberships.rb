# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "io/console"
require_relative "helpers/format"
require_relative "helpers/sac_logo"
require_relative "memberships/promote_neuanmeldung"

module TTY
  class ManageMemberships
    include Helpers::Format

    TASKS = %w[promote_neuanmeldung]

    def self.run = new.run

    def run
      trap_ctrl_c
      Helpers::SacLogo.new.print
      puts bold light_yellow("Welcome to the ") +
        light_red("SAC ") +
        light_cyan("Membership Management ") +
        light_yellow("CLI!")
      show_main_menu
      print_byebye
    end

    private

    def trap_ctrl_c
      Signal.trap("INT") do
        print_byebye
        exit(1)
      end
    end

    def show_main_menu
      loop do # This loop runs until explicitly broken
        puts "\nHow can I help you today?"
        puts "1) Promote Neuanmeldung to Membership " +
          gray("(Stammsektion or Zusatzsektion)")
        puts "q) Exit " # Updated label
        print "Please choose an option: "

        choice = STDIN.getch

        # Since getch doesn't echo, print a newline for cleaner formatting
        # after the user presses the key.
        puts

        case choice
        when "1"
          Memberships::PromoteNeuanmeldung.new.run
        when "q"
          break
        else
          puts "Invalid choice '#{choice}'. Please try again."
        end
      end
    end

    def print_byebye
      puts light_yellow "\nHave a great day, happy to assist you next time!"
    end
  end
end
