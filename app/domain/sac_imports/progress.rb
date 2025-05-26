# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports
  class Progress
    SPINNER_CHARS = "•○◉◌".chars.freeze
    # SPINNER_CHARS = "▲▶▼◀".chars.freeze

    def initialize(size, title: "Progress", silent: false, output: $stdout)
      @title = title
      @start_at = Time.current
      @last_output_at = Time.current
      @spinner_position = 0
      @size = size
      @position = 0
      @silent = silent
      @output = output
      @mutex = Mutex.new
    end

    def step
      @mutex.synchronize do
        @position += 1

        return if @silent

        position_percent = (@position.to_f / @size * 100).round
        progress_bar = "=" * (position_percent / 5.0).round

        now = Time.current
        next unless now - @last_output_at >= 0.5
        @last_output_at = now
        @spinner_position += 1

        printf("\r#{@title}: [%-20s] %d%%  %s  %d/s ETA: %s  ", progress_bar, position_percent,
          spinner(@spinner_position), throughput, eta.seconds.from_now)
      end
    end

    def eta
      return 0 if @position >= @size

      elapsed = Time.current - @start_at
      elapsed / @position * (@size - @position)
    end

    def throughput
      elapsed = Time.current - @start_at
      (@position.to_f / elapsed).round(2)
    end

    private

    def spinner(index)
      spinner_position = index % SPINNER_CHARS.size
      SPINNER_CHARS[spinner_position]
    end
  end
end
