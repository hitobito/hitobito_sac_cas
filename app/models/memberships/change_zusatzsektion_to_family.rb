# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Memberships::ChangeZusatzsektionToFamily
  def initialize(role)
    @role = role
  end

  def save!
    Memberships::FamilyMutation.new(@role.person).change_zusatzsektion_to_family!(@role)
  end
end
