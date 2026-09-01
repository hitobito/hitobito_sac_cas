# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class CornercardApplicationsRow < Export::Tabular::Row
    def initialize(entry, format = nil)
      super(entry.person, format)
      @upload = entry
    end

    def id
      entry.id
    end

    def mobile
      entry.phone_number_mobile&.number
    end
  end
end
