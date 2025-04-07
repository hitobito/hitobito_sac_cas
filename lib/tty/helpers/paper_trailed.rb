# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module Helpers
    module PaperTrailed
      def set_papertrail_metadata(mutation_id: SecureRandom.uuid)
        controller_info = {mutation_id:}
        whodunnit = self.class.name
        PaperTrail.request.enabled = true
        PaperTrail.request.whodunnit = whodunnit
        PaperTrail.request.controller_info = controller_info
      end
    end
  end
end
