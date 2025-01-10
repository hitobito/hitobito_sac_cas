# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People
  class CacheMembershipYearsJob < RecurringJob
    def next_run
      Time.current.tomorrow.change(hour: 0, min: 5)
    end

    def perform_internal
      Person.with_membership_years.find_each do |person|
        person.update_cached_membership_years!
      end
    end
  end
end
