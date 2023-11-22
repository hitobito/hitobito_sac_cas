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

        dependent_roles.each do |role|
          role.update!(terminated: true, delete_on: terminate_on)
        end
      end
    end
  end

  # Returns all roles that will be terminated.
  def affected_roles
    [role] + dependent_roles
  end

  private

  # For a Group::SektionsMitglieder::Mitglied role that is in the primary group of the person,
  # this returns all other Group::SektionsMitglieder::Mitglied roles of the same person.
  # For any other role type or role that is not in the primary group, returns an empty array.
  def dependent_roles
    return [] unless role.is_a?(Group::SektionsMitglieder::Mitglied) && role.in_primary_group?

    Group::SektionsMitglieder::Mitglied.
      where(person_id: role.person_id).
      where.not(id: role.id)
  end

end
