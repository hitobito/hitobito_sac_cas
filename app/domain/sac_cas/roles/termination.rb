# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Roles::Termination
  extend ActiveSupport::Concern

  def self.prepended(base)
    base.extend(ClassMethods)
  end

  def call
    return false unless valid?
    return super unless sac_terminatable?

    Role.transaction do
      self.class.terminate(affected_roles, terminate_on)
      if role.person.sac_family.member?
        role.person.sac_family.update_terminated_roles
      end
      true
    end
  end

  private

  def sac_terminatable?
    terminatable_mitglied_role_types
      .include?(role.type)
  end

  def affected_roles
    [role] + dependent_roles
  end

  def terminatable_mitglied_role_types
    [Group::SektionsMitglieder::Mitglied,
     Group::SektionsMitglieder::MitgliedZusatzsektion]
      .collect(&:sti_name)
  end

  # For a Group::SektionsMitglieder::Mitglied role, this returns all other
  # Group::SektionsMitglieder::MitgliedZusatzsektion roles of the same person.
  # For any other role type returns an empty array.
  def dependent_roles
    return [] unless role.is_a?(Group::SektionsMitglieder::Mitglied)

    Group::SektionsMitglieder::MitgliedZusatzsektion.
      where(person_id: role.person_id)
  end

  module ClassMethods
    def terminate(roles, delete_on)
      # use update_all to not trigger any validations while terminating
      Role.where(id: roles.map(&:id)).update_all(
        delete_on: delete_on,
        terminated: true,
        updated_at: Time.current
      )
    end
  end
end
