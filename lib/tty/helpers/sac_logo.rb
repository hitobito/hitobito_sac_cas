# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module Helpers
    class SacLogo
      def print
        puts File.read(File.join(File.dirname(__FILE__), "sac_logo.ascii"))
      end
    end
  end
end
