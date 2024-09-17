# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# Creates/extends sac memberships after membership invoice has been paid.
class Invoices::SacMemberships::MembershipManager
  attr_reader :person, :group, :year, :member

  def initialize(person, group, year)
    @person = person
    @group = group
    @year = year

    context = Invoices::SacMemberships::Context.new(Time.zone.today)
    @member ||= Invoices::SacMemberships::Member.new(person, context)
  end

  def update_membership_status
    ActiveRecord::Base.transaction do
      if stammsektion?
        extend_membership_duration
      elsif neuanmeldung_stammsektion?
        set_confirmed_at
        update_role_to_stammsektion_mitglied(person)
        update_family_roles_to_stammsektion_mitglied if family_main_person?
      elsif neuanmeldung_zusatzsektion?
        update_roles_to_zusatzsektion_mitglied(person)
        update_family_roles_to_zusatzsektion_mitglied if family_main_person?
      end
    end
  end

  private

  def extend_membership_duration
    roles_for_update = []

    roles_for_update << person.sac_membership.stammsektion_role
    roles_for_update.concat(person.sac_membership.zusatzsektion_roles.reject(&:terminated?))
    if family_main_person?
      roles_for_update.concat(family_memberships.map(&:stammsektion_role))
      roles_for_update.concat(family_memberships.flat_map(&:zusatzsektion_roles)
                      .select { |zusatzsektion| zusatzsektion.beitragskategorie&.family? })
    end

    roles_for_update.each do |role|
      role.update!(delete_on: [Date.new(year).end_of_year, role.delete_on].max)
    end
  end

  def update_role_to_stammsektion_mitglied(person)
    person.sac_membership.neuanmeldung_stammsektion_role.destroy
    create_mitglied_role(person)
  end

  def update_roles_to_zusatzsektion_mitglied(person)
    person.sac_membership.neuanmeldung_zusatzsektion_roles.each do |role|
      role.destroy
      create_mitglied_zusatzsektion_role(person)
    end
  end

  def update_family_roles_to_stammsektion_mitglied
    person.household_people.each { |family_member| update_role_to_stammsektion_mitglied(family_member) }
  end

  def update_family_roles_to_zusatzsektion_mitglied
    person.household_people.each { |family_member| update_roles_to_zusatzsektion_mitglied(family_member) }
  end

  def create_mitglied_role(person)
    Group::SektionsMitglieder::Mitglied.create!(person: person, group: mitglieder_sektion, delete_on: Date.new(year).end_of_year, created_at: Time.zone.now)
  end

  def create_mitglied_zusatzsektion_role(person)
    Group::SektionsMitglieder::MitgliedZusatzsektion.create!(person: person, group: mitglieder_sektion, delete_on: Date.new(year).end_of_year, created_at: Time.zone.now)
  end

  def mitglieder_sektion
    @mitglieder_sektion ||= group.layer_group.children.where(type: Group::SektionsMitglieder.sti_name).first
  end

  def stammsektion?
    person.sac_membership.active? && person.sac_membership.stammsektion_role.layer_group == group.layer_group
  end

  def neuanmeldung_stammsektion?
    person.sac_membership.neuanmeldung_stammsektion_role&.layer_group == group.layer_group
  end

  def neuanmeldung_zusatzsektion?
    person.sac_membership.neuanmeldung_zusatzsektion_roles.first.layer_group == group.layer_group
  end

  def family_main_person?
    person.sac_family_main_person?
  end

  def family_memberships
    member.family_members.map(&:sac_membership)
  end

  def set_confirmed_at
    person.confirmed_at = Time.zone.now if person.confirmed_at.blank?
  end
end
