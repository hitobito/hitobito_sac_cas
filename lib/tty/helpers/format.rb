# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module Helpers
    # Provides methods to add ANSI colors and styles to terminal output.
    module Format
      # ANSI escape code prefix and suffix
      ANSI_START = "\e[".freeze
      ANSI_END = "m".freeze
      ANSI_RESET = "\e[0m".freeze

      # Basic foreground color codes
      COLORS = {
        black: 30,
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        magenta: 35,
        cyan: 36,
        white: 37,
        gray: 90,
        light_red: 91,
        light_green: 92,
        light_yellow: 93,
        light_blue: 94,
        light_magenta: 95,
        light_cyan: 96,
        light_white: 97
      }.freeze

      # Basic style codes
      STYLES = {
        bold: 1,
        dim: 2,
        italic: 3,
        underline: 4,
        blink: 5
      }.freeze

      # General method to wrap text with ANSI codes
      # Usage: format_text("Hello", color: :red, style: :bold)
      def format_text(text, color: nil, style: nil)
        codes = []
        codes << STYLES[style] if style && STYLES[style]
        codes << COLORS[color] if color && COLORS[color]

        return text if codes.empty? # Return raw text if no formatting applied

        "#{ANSI_START}#{codes.join(";")}#{ANSI_END}#{text}#{ANSI_RESET}"
      end

      # --- Direct Style Helpers ---
      STYLES.each_key do |style_name|
        define_method(style_name) do |text|
          format_text(text, style: style_name)
        end
      end

      # --- Direct Color Helpers ---
      # Defines methods like red(text), green(text), etc.
      COLORS.each_key do |color_name|
        define_method(color_name) do |text|
          format_text(text, color: color_name)
        end

        STYLES.each_key do |style_name|
          define_method("#{style_name}_#{color_name}") do |text|
            format_text(text, color: color_name, style: style_name)
          end
        end
      end

      def error(text)
        bold(red(text))
      end
    end
  end
end
