# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Roles::Termination
  extend ActiveSupport::Concern

  def call
    return false unless valid?
    return super unless sac_terminatable?

    Role.transaction do
      self.class.terminate(affected_roles, terminate_on)
      if role.person.sac_membership.family?
        update_terminated_roles(role.person)
      end
      true
    end
  end

  def affected_roles
    super + dependent_roles
  end

  def affected_people
    return [] unless stammsektion_membership? && role.beitragskategorie&.family?

    main_person.household.people - [main_person]
  end

  private

  def sac_terminatable?
    terminatable_mitglied_role_types
      .include?(role.type)
  end

  def terminatable_mitglied_role_types
    SacCas::MITGLIED_ROLES.collect(&:sti_name)
  end

  # For a Group::SektionsMitglieder::Mitglied role, this returns all other
  # Group::SektionsMitglieder::MitgliedZusatzsektion roles of the same person.
  # For any other role type returns an empty array.
  def dependent_roles
    return [] unless stammsektion_membership?

    Group::SektionsMitglieder::MitgliedZusatzsektion.
      where(person_id: role.person_id)
  end

  def stammsektion_membership?
     role.is_a?(Group::SektionsMitglieder::Mitglied)
  end

  # deprecated, moved here from `People::SacFamily`, will get removed with #680
  def update_terminated_roles(person)
    terminated_roles = person
                         .roles
                         .where(type: terminatable_mitglied_role_types,
                                terminated: true,
                                beitragskategorie: :family)

    affected_family_roles = Role
                              .where(type: terminatable_mitglied_role_types,
                                     group_id: terminated_roles.collect(&:group_id),
                                     terminated: false,
                                     beitragskategorie: :family,
                                     person_id: person.household.people.collect(&:id))

    delete_on = terminated_roles.first.delete_on
    Roles::Termination.terminate(affected_family_roles, delete_on)
  end

  class_methods do
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
