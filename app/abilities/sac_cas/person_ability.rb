# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PersonAbility
  extend ActiveSupport::Concern

  included do
    on(::Person) do
      general(:primary_group).if_not_preferred_primary_role

      permission(:any).may(:memberships).herself_if_basic_permissions_only

      # first overwrite all rules with action :history which have been defined in
      # the youth wagon with deny. Then redefine the rule with SAC logic.
      for_self_or_manageds do
        permission(:any).may(:history).never
      end
      permission(:any).may(:history).herself_and_manageds_unless_basic_permissions_only
    end
  end

  def never
    false
  end

  def if_not_preferred_primary_role
    primary = Groups::Primary.new(person)
    !primary.preferred_exists?
  end

  def herself_if_basic_permissions_only
    return false unless user.basic_permissions_only?

    herself
  end

  # If the user has basic permissions only, return always false.
  # Otherwise, return true if the person is herself or if the user is a manager of the person.
  def herself_and_manageds_unless_basic_permissions_only
    return false if user.basic_permissions_only?

    herself || user.people_manageds.pluck(:managed_id).include?(person.id)
  end

end
