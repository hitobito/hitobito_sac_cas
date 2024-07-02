# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# DEPRECATED: This class is no longer used and will be removed once the termination wizard is implemented.
class People::SacFamily

  delegate :household_key, to: '@person'

  def initialize(person)
    @person = person
  end

  def update_terminated_roles
    terminated_roles = @person
                       .roles
                       .where(type: terminatable_member_role_types,
                              terminated: true,
                              beitragskategorie: :family)

    affected_family_roles = Role
                            .where(type: terminatable_member_role_types,
                                   group_id: terminated_roles.collect(&:group_id),
                                   terminated: false,
                                   beitragskategorie: :family,
                                   person_id: @person.household.people.collect(&:id))

    delete_on = terminated_roles.first.delete_on
    Roles::Termination.terminate(affected_family_roles, delete_on)
  end

  private

  def terminatable_member_role_types
    SacCas::MITGLIED_ROLES.select(&:terminatable).map(&:sti_name)
  end

end
