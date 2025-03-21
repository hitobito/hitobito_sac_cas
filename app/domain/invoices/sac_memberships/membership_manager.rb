# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# Creates/extends sac memberships after membership invoice has been paid.
class Invoices::SacMemberships::MembershipManager
  attr_reader :person, :group, :year, :member, :today, :end_of_year

  def initialize(person, group, year)
    @person = person
    @group = group
    @year = year
    @end_of_year = Date.new(year).end_of_year
    @today = Time.zone.today

    context = Invoices::SacMemberships::Context.new(today)
    @member ||= Invoices::SacMemberships::Member.new(person, context)
  end

  def update_membership_status
    ActiveRecord::Base.transaction do
      if member_already?
        extend_membership_duration
      elsif member_in_past_year?
        create_new_membership_roles
      elsif neuanmeldung_for_stammsektion?
        create_stammsektion_membership_from_neuanmeldung
      elsif neuanmeldung_zusatzsektion?
        create_zusatzsektion_membership_from_neuanmeldung
      end
    end
  end

  private

  def extend_membership_duration
    relevant_roles_for(person.sac_membership.stammsektion_role).each do |role|
      role.update!(end_on: [Date.new(year).end_of_year, role.end_on].compact.max)
    end
  end

  def create_new_membership_roles
    relevant_roles_for(expired_stammsektion_role).each do |previous_role|
      create_new_role(previous_role.person, previous_role.type.constantize, previous_role.group)
    end
  end

  def relevant_roles_for(stammsektion_role)
    membership = People::SacMembership.new(person, date: stammsektion_role.active? ? Time.zone.today : stammsektion_role.end_on)

    relevant_roles = []
    relevant_roles << membership.stammsektion_role
    relevant_roles.concat(membership.zusatzsektion_roles.reject(&:terminated?))
    relevant_roles.concat(membership.membership_prolongable_roles.reject(&:terminated?))

    if family_main_person?
      person.household_people.each do |family_member|
        family_member_membership = People::SacMembership.new(family_member, date: stammsektion_role.active? ? Time.zone.today : stammsektion_role.end_on)

        relevant_roles << family_member_membership.stammsektion_role
        relevant_roles.concat(family_member_membership.zusatzsektion_roles.reject(&:terminated?)
          .select { |zusatzsektion| zusatzsektion.beitragskategorie&.family? })
        relevant_roles.concat(family_member_membership.membership_prolongable_roles)
      end
    end

    relevant_roles
  end

  def create_stammsektion_membership_from_neuanmeldung
    set_confirmed_at
    update_role_to_stammsektion_mitglied(person)
    update_family_roles_to_stammsektion_mitglied if family_main_person?
  end

  def update_role_to_stammsektion_mitglied(person)
    neuanmeldung_role = person.sac_membership.neuanmeldung_stammsektion_role
    neuanmeldung_role.destroy
    new_role = create_new_role(person, Group::SektionsMitglieder::Mitglied, beitragskategorie: neuanmeldung_role.beitragskategorie)
    send_confirmation_mail(person, new_role)
  end

  def create_zusatzsektion_membership_from_neuanmeldung
    update_roles_to_zusatzsektion_mitglied(person)
    update_family_roles_to_zusatzsektion_mitglied if family_main_person?
  end

  def update_roles_to_zusatzsektion_mitglied(person)
    role = person.sac_membership.neuanmeldung_zusatzsektion_roles.find { |role| role.layer_group == group.layer_group }
    if role
      role.destroy
      end_on = [person.sac_membership.stammsektion_role.end_on, end_of_year].min
      start_on = end_on.past? ? end_on : today
      new_role = create_new_role(person, Group::SektionsMitglieder::MitgliedZusatzsektion, start_on: start_on, end_on: end_on, beitragskategorie: role.beitragskategorie)

      send_confirmation_mail(person, new_role)
    end
  end

  def send_confirmation_mail(person, role)
    Invoices::SacMembershipsMailer.confirmation(person, role.group.parent, role.beitragskategorie).deliver_later if person.email.present?
  end

  def update_family_roles_to_stammsektion_mitglied
    person.household_people.each { |family_member| update_role_to_stammsektion_mitglied(family_member) }
  end

  def update_family_roles_to_zusatzsektion_mitglied
    person.household_people.each { |family_member| update_roles_to_zusatzsektion_mitglied(family_member) }
  end

  def create_new_role(person, role_type, group = mitglieder_sektion, start_on: today, end_on: end_of_year, beitragskategorie: nil)
    attributes = {group: group, person: person, end_on: end_on, start_on: start_on, beitragskategorie: beitragskategorie}.compact
    role_type.create!(attributes)
  end

  def mitglieder_sektion
    @mitglieder_sektion ||= group.layer_group.children.where(type: Group::SektionsMitglieder.sti_name).first
  end

  def member_already?
    person.sac_membership.active? && person.sac_membership.stammsektion_role.layer_group == group.layer_group
  end

  def member_in_past_year?
    !person.sac_membership.active? && expired_stammsektion_role&.layer_group == group.layer_group
  end

  def neuanmeldung_for_stammsektion?
    person.sac_membership.neuanmeldung_stammsektion_role&.layer_group == group.layer_group
  end

  def neuanmeldung_zusatzsektion?
    person.sac_membership.neuanmeldung_zusatzsektion_roles.any? { |role| role.layer_group == group.layer_group }
  end

  def family_main_person?
    person.sac_family_main_person?
  end

  def set_confirmed_at
    person.update_column(:confirmed_at, Time.zone.now) if person.confirmed_at.blank?
  end

  # used to get non active stammsektion role of last year, in case a invoice is payed too late, this case can occur
  def expired_stammsektion_role
    @person.roles.with_inactive
      .where(type: SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name), end_on: [Date.new(year)..])
      .order(:end_on)
      .reject(&:terminated?)
      .last
  end
end
