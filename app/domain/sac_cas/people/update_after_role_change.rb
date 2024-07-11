# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::People::UpdateAfterRoleChange
  extend ActiveSupport::Concern

  def set_first_primary_group
    return super if person.primary_group_id.nil? || no_role_in_primary_group?
    return if Groups::Primary.new(person).preferred?(person.primary_group)
    return if person.primary_group_id == newest_group_id

    person.update_column(:primary_group_id, newest_group_id)
  end

  private

  def newest_group_id
    Groups::Primary.new(person).group&.id.presence || super
  end
end
