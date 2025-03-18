# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class MembershipYearsColumn < TableDisplays::PublicColumn
    prepend TableDisplays::People::SektionMemberAdminVisible

    def required_model_attrs(attr)
      [:cached_membership_years]
    end

    def sort_by(attr)
      nil
    end
  end
end
