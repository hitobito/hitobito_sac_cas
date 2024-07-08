# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Qualifications::Expiring
  class << self
    def entries(finish_at)
      Qualification.where(finish_at: finish_at).joins(latest_expirations_join).includes(:person)
    end

    private

    def latest_expiring_qualifications
      Qualification.select("MAX(finish_at) as finish_at, person_id").group(:person_id).to_sql
    end

    def latest_expirations_join
      "INNER JOIN (#{latest_expiring_qualifications}) as l" \
        " ON l.person_id = qualifications.person_id" \
        " AND l.finish_at = qualifications.finish_at"
    end
  end
end
