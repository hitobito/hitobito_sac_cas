# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards
  module Steps
    class ChooseSektionUnrestricted < ChooseSektion
      # Act the same as the ChooseSektion step
      def self.step_name
        "choose_sektion"
      end
      self.partial = "wizards/steps/choose_sektion"

      # Always allow self service
      def self_service?
        true
      end
    end
  end
end
