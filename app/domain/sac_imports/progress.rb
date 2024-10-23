# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports
  class Progress
    def initialize(size, silent: false, output: $stdout)
      @start_at = Time.now
      @size = size
      @position = 0
      @silent = silent
      @output = output
      @spinner = Enumerator.new do |e|
        loop do
          e.yield "|"
          e.yield "/"
          e.yield "-"
          e.yield "\\"
        end
      end
    end

    def step
      @position += 1

      return if @silent

      relative_position = (100 * @position.to_f / @size).round
      progress = "=" * relative_position
      printf("\rProgress: [%-100s] %d%% %s ETA: %s", progress, relative_position, @spinner.next, eta.seconds.from_now)
    end

    def eta
      return Time.now if @position >= @size

      elapsed = Time.now - @start_at
      elapsed / @position * (@size - @position)
    end
  end
end
