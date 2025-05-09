# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/Output, Rails/Exit

module TTY
  class ManageMemberships
    prepend TTY::Command
    include Helpers::Format

    self.description = "Manage memberships"

    MENU_ACTIONS = {
      "p" => TTY::Memberships::PromoteNeuanmeldung,
      "s" => TTY::Memberships::SwapStammsektion,
      "u" => TTY::Memberships::UndoTermination,
    }.freeze

    def run
      loop do
        break unless CliMenu.new(menu_actions: MENU_ACTIONS).run
      end
    end

  end
end

# rubocop:enable Rails/Output, Rails/Exit
