# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  class CliMenu
    include TTY::Helpers::Format

    # Error class for signaling to exit the menu loop gracefully
    class ExitMenu < StandardError; end

    class AskAgain < StandardError; end

    # --- Configuration ---
    # @param menu_actions [Hash] Hash defining menu options.
    #   Keys are the characters to press.
    #   Values are hashes with :description (String) and :action (Proc).
    # @param prompt [String] The prompt message shown before input.
    # @param invalid_choice_message [String] Message for invalid input.
    def initialize(menu_actions:, prompt: "\nPlease choose an option", invalid_choice_message: "Invalid choice '%s'. Please try again.")
      @menu_actions = add_quit_option(menu_actions)
      @prompt = prompt
      @invalid_choice_message = invalid_choice_message
      @input_mode = determine_input_mode # :single_char or :multi_char
      validate_menu_actions!
    end

    # --- Public Interface ---

    # Runs the menu loop until an action signals exit or an error occurs.
    def run
      loop do
        print_menu
        print "#{@prompt}: "
        choice = read_input
        return handle_choice(choice)
      rescue AskAgain
        next # Continue the loop if an action raises AskAgain
      end
    rescue ExitMenu
      # Do nothing
    end

    private

    def add_quit_option(menu_actions)
      menu_actions.key?("q") ? menu_actions : menu_actions.merge("q" => quit_action)
    end

    # Determines if single-char or multi-char input should be used
    def determine_input_mode
      # If ANY key is longer than 1 character, switch to multi-character mode
      (@menu_actions.keys.any? { |key| key.to_s.length > 1 }) ? :multi_char : :single_char
    end

    def quit_action
      {description: "Exit menu", action: -> { raise ExitMenu }, style: :dim}
    end

    # Prints the available menu options.
    def print_menu
      puts # Ensure a blank line before the menu

      keys_length = @menu_actions.keys.map { _1.length }.max

      @menu_actions.each do |key, args|
        args in { description:, action:, **format }
        # Format the key part (e.g., "p)" or "promote-all)")
        key_part = "#{key})"
        # Left-justify the key part using the calculated width
        padded_key_part = key_part.ljust(keys_length + 1)
        # Print the padded key part followed by the description
        puts format_text("#{padded_key_part} #{description}",
          color: format[:color],
          style: format[:style])
      end
    end

    # Reads input based on the determined mode (:single_char or :multi_char)
    def read_input
      if @input_mode == :single_char
        read_single_char_input
      else
        read_multi_char_input
      end
    end

    # Reads a single character from standard input without waiting for Enter.
    def read_single_char_input
      $stdin.getch.tap do |char|
        if char == "\u0003" # Check for Ctrl+C explicitly in getch
          quit
        end
        # Provide visual feedback by echoing the character or a newline
        # If char is a control char it might not print well, so just newline
        if char.match?(/^[[:print:]]$/)
          print char # Echo printable chars
        end
        puts # Always add a newline for clean formatting
      end
    end

    # Reads a line of text and removes trailing newline
    def read_multi_char_input = $stdin.gets.chomp

    # Handles the user's choice based on the mapping.
    # Executes the action or prints an error message.
    # Actions can raise CliMenu::ExitMenu to stop the menu loop.
    def handle_choice(choice)
      action_config = @menu_actions[choice]

      unless action_config
        puts red(format(@invalid_choice_message, choice))
        raise AskAgain
      end

      puts

      if action_config[:action].respond_to?(:call)
        # Execute the action associated with the choice
        action_config[:action].call
      else
        # Action is not callable, just return the value
        action_config[:action]
      end
    end

    # Validates the structure of the menu_actions hash during initialization.
    def validate_menu_actions!
      unless @menu_actions.is_a?(Hash) && !@menu_actions.empty?
        raise ArgumentError, "menu_actions must be a non-empty Hash"
      end

      @menu_actions.each do |key, config|
        unless key.to_s.present?
          raise ArgumentError, "Menu action keys must be non-empty Strings (got #{key.class.name} #{key.inspect})"
        end
        config_hash = config.deconstruct_keys(nil)
        unless config_hash.key?(:description) && config_hash.key?(:action)
          raise ArgumentError, "Menu action for key '#{key}' must be a Hash with :description and :action keys"
        end
        unless config_hash[:description].is_a?(String)
          raise ArgumentError, "Description for key '#{key}' must be a String"
        end
      end
    end
  end
end
