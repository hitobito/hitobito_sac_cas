# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::RolesHelper

  def format_role_membership_years(role)
    f(role.membership_years) if role.is_a?(Group::SektionsMitglieder::Mitglied)
  end

end
