# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::HouseholdAsideMemberComponent
  extend ActiveSupport::Concern

  prepended do
    def person_entry(member)
      content_tag(:strong) do
        person_link(member)
      end + member_years(member)
    end

    def member_years(member)
      " (#{member.years})" if member.years
    end
  end
end
