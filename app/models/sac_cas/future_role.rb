# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::FutureRole

  def start_on
    convert_on
  end

  def end_on
    convert_on.end_of_year
  end

  def build_new_role
    return super unless becomes_mitglied_role?

    super.tap do |role|
      role.created_at = convert_on
      role.delete_on = convert_on.end_of_year
    end
  end

  def validate_target_type?
    becomes_mitglied_role?
  end

  def becomes_mitglied_role?
    target_type <= SacCas::Role::MitgliedCommon || false
  end

end
