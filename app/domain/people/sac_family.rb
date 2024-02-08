# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::SacFamily

  FAMILY_MEMBER_ROLE_TYPES = SacCas::MITGLIED_HAUPTSEKTION_ROLES

  delegate :household_key, to: '@person'

  def initialize(person)
    @person = person
  end

  #def create(stammsektion)
  #end

  # trigger after:
  # - adding a new person to household
  # - adding a new child (managed)
  # - adding a manager to a child (manager)
  #def update!
    #update_children
    #update_adults
  #end

  def update_terminated_roles
    terminated_roles = @person
      .roles
      .where(type: terminatable_family_member_role_types,
             terminated: true,
             beitragskategorie: :familie)

    affected_family_roles = Role
      .where(type: terminatable_family_member_role_types,
             group_id: terminated_roles.collect(&:group_id),
             terminated: false,
             beitragskategorie: :familie,
             person_id: family_members.collect(&:id))

    delete_on = terminated_roles.first.delete_on
    Roles::Termination.terminate(affected_family_roles, delete_on)
  end

  #def change_stammsektion
  #end

  #def add_zusatzsektion
  #end

  # make sure all family members are approved at the same time
  #def approve_neuanmeldungen
  #end

  def member?
    household_key.present? &&
      family_stammsektion.present?
  end

  def family_members
    return [] unless member?

    family_stammsektion.people
      .distinct
      .joins(:roles)
      .where(roles: { type: family_stammsektion_role_types, beitragskategorie: :familie },
             people: { household_key: @person.household_key })
  end

  def id
    return unless member?

    /\AF/ =~ household_key ? household_key : "F#{household_key}"
  end

  private

  def family_stammsektion
    @family_stammsektion ||=
      Role.find_by(person: @person,
                   beitragskategorie: :familie,
                   type: family_stammsektion_role_types)
      .try(:group)
  end

  #def update_children
     #add all children to household
     #add all mitglieder roles with Beitragskategorie familie to children
  #end

  #def update_adults
     #is there adults in same household that are allowed to get mitglied familie roles?
  #end

  def family_stammsektion_role_types
    FAMILY_MEMBER_ROLE_TYPES.collect(&:sti_name)
  end

  def terminatable_family_member_role_types
    [Group::SektionsMitglieder::Mitglied,
     Group::SektionsMitglieder::MitgliedZusatzsektion].collect(&:sti_name)
  end

end
