# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Roles::Termination

  def call
    Role.transaction do
      super.tap do |success|
        next unless success # terminating role failed, do not terminate dependent roles

        terminate(dependent_roles)
        terminate(family_member_roles)
      end
    end
  end

  # Returns all roles that will be terminated.
  def affected_roles
    @affected_roles ||= [role] + dependent_roles
  end

  def family_member_roles
    return [] unless role.is_a?(Group::SektionsMitglieder::Mitglied) &&
      role.beitragskategorie.familie?

    group_ids = affected_roles.map(&:group_id)

    Group::SektionsMitglieder::Mitglied.
      familie.
      where(person_id: role.person.household_people, group_id: group_ids)
  end

  private

  # For a Group::SektionsMitglieder::Mitglied role, this returns all other
  # Group::SektionsMitglieder::Mitglied roles of the same person.
  # For any other role type returns an empty array.
  def dependent_roles
    return [] unless role.is_a?(Group::SektionsMitglieder::Mitglied)

    Group::SektionsMitglieder::Mitglied.
      where(person_id: role.person_id).
      where.not(id: role.id)
  end

  def terminate(roles)
    roles.each do |role|
      role.delete_on = terminate_on
      role.write_attribute(:terminated, true)
      role.save!
    end
  end

end
