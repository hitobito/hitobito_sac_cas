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
    @beginning_of_year = Date.new(year)
    @end_of_year = @beginning_of_year.end_of_year
    @today = Time.zone.today

    context = Invoices::SacMemberships::Context.new(today)
    @member = Invoices::SacMemberships::Member.new(person, context)
  end

  def update_membership_status
    ActiveRecord::Base.transaction do
      if member_already?
        extend_membership_duration
      elsif neuanmeldung_for_stammsektion?
        create_stammsektion_membership_from_neuanmeldung
      elsif member_in_past_year?
        create_new_membership_roles
      elsif neuanmeldung_zusatzsektion?
        create_zusatzsektion_membership_from_neuanmeldung
      else
        log_missing_membership
      end
    end
  end

  private

  def extend_membership_duration
    relevant_roles_for(person.sac_membership.stammsektion_role).each do |role|
      role.update!(end_on: [end_of_year, role.end_on].compact.max)
    end
  end

  def create_new_membership_roles
    restore_household if restore_household?

    relevant_roles_for(expired_stammsektion_role).each do |previous_role|
      create_new_role(previous_role.person, previous_role.type.constantize, previous_role.group)
    end
  end

  def relevant_roles_for(stammsektion_role)
    date = reference_date(stammsektion_role)

    collect_roles_for_person(person, date) +
      collect_roles_for_housemates(person, date)
  end

  def reference_date(stammsektion_role)
    if stammsektion_role.active?
      (today.year < year) ? @beginning_of_year : today
    else
      stammsektion_role.end_on
    end
  end

  def collect_roles_for_person(person, date, only_family: false) # rubocop:disable Metrics/MethodLength
    membership = People::SacMembership.new(person, date:)

    stammsektion_role = membership.stammsektion_role
    applicable_zusatzsektion_roles = membership.zusatzsektion_roles.reject(&:terminated?)
    other_prolongable_roles = membership.membership_prolongable_roles.reject(&:terminated?)

    if only_family
      unless stammsektion_role.beitragskategorie.family?
        stammsektion_role = nil
        other_prolongable_roles = []
      end
      applicable_zusatzsektion_roles.select! { |r| r.beitragskategorie.family? }
    end

    [
      stammsektion_role,
      *applicable_zusatzsektion_roles,
      *other_prolongable_roles
    ].compact
  end

  def collect_roles_for_housemates(person, date)
    return [] unless person.sac_family_main_person?

    person.household_people.flat_map do |family_member|
      collect_roles_for_person(family_member, date, only_family: true)
    end
  end

  def create_stammsektion_membership_from_neuanmeldung
    update_role_to_stammsektion_mitglied(person)
    update_family_roles_to_stammsektion_mitglied if family_main_person?
  end

  def update_role_to_stammsektion_mitglied(person)
    neuanmeldung_role = person.sac_membership.neuanmeldung_stammsektion_role
    neuanmeldung_role.destroy
    new_role = create_new_role(
      person,
      Group::SektionsMitglieder::Mitglied,
      beitragskategorie: neuanmeldung_role.beitragskategorie
    )
    send_confirmation_mail(person, new_role)
  end

  def create_zusatzsektion_membership_from_neuanmeldung
    update_roles_to_zusatzsektion_mitglied(person)
    update_family_roles_to_zusatzsektion_mitglied if family_main_person?
  end

  def update_roles_to_zusatzsektion_mitglied(person)
    role = person.sac_membership.neuanmeldung_zusatzsektion_roles.find do |role|
      role.layer_group == group.layer_group
    end
    return unless role

    role.destroy
    end_on = [person.sac_membership.latest_stammsektion_role.end_on, end_of_year].min
    start_on = end_on.past? ? end_on : today
    new_role = create_new_role(
      person,
      Group::SektionsMitglieder::MitgliedZusatzsektion,
      start_on: start_on,
      end_on: end_on,
      beitragskategorie: role.beitragskategorie
    )

    send_confirmation_mail(person, new_role)
  end

  def send_confirmation_mail(person, role)
    if person.email.present?
      Invoices::SacMembershipsMailer
        .confirmation(person, role.group.parent, role.beitragskategorie)
        .deliver_later
    end
  end

  def update_family_roles_to_stammsektion_mitglied
    person.household_people.each do |family_member|
      update_role_to_stammsektion_mitglied(family_member)
    end
  end

  def update_family_roles_to_zusatzsektion_mitglied
    person.household_people.each do |family_member|
      update_roles_to_zusatzsektion_mitglied(family_member)
    end
  end

  def create_new_role(person, role_type, group = mitglieder_sektion, start_on: today,
    end_on: end_of_year, beitragskategorie: nil)
    role_type.create!(
      group: group,
      person: person,
      end_on: end_on,
      start_on: start_on,
      beitragskategorie: beitragskategorie
    )
  end

  def mitglieder_sektion
    @mitglieder_sektion ||=
      group.layer_group.children.where(type: Group::SektionsMitglieder.sti_name).first
  end

  def member_already?
    person.sac_membership.active? &&
      person.sac_membership.stammsektion_role.layer_group == group.layer_group
  end

  def member_in_past_year?
    !person.sac_membership.active? && expired_stammsektion_role&.layer_group == group.layer_group
  end

  def neuanmeldung_for_stammsektion?
    person.sac_membership.neuanmeldung_stammsektion_role&.layer_group == group.layer_group
  end

  def neuanmeldung_zusatzsektion?
    person.sac_membership.neuanmeldung_zusatzsektion_roles.any? do |role|
      role.layer_group == group.layer_group
    end
  end

  def family_main_person?
    person.sac_family_main_person?
  end

  # used to get non active stammsektion role of last year, in case a invoice is payed too late,
  # this case can occur
  def expired_stammsektion_role
    @person.roles.with_inactive
      .where(type: SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name),
        end_on: @beginning_of_year..)
      .order(:end_on)
      .reject(&:terminated?)
      .last
  end

  # Find the matching family members Stammsektion roles with the same
  # family_id and end_on
  def expired_family_member_roles
    Group::SektionsMitglieder::Mitglied.with_inactive
      .where(
        family_id: expired_stammsektion_role.family_id,
        end_on: expired_stammsektion_role.end_on
      )
      .where.not(person_id: person.id)
  end

  # For family memberhips, if the membership role is expired, the household has been
  # disbanded. It must be restored before creating new family membership roles.
  # This is the case if the stammsektion role is of family type but the person has no household_key.
  def restore_household?
    person.household_key.blank? &&
      expired_stammsektion_role.beitragskategorie.family? &&
      expired_stammsektion_role.family_id?
  end

  # Restores the household of the person based on the expired family member roles.
  # Notes:
  # * `maintain_sac_family: false` must be used to disable role handling in the Household model
  #   as we handle the roles ourselves in this class.
  # * Save with `context: :create` to skip validations on the Household model. We need to restore
  #   the household even if validations would fail.
  # * As `maintain_sac_family` is false, the Household will not manage PeopleManagers. By calling
  #  `set_family_main_person!` manually afterwards, the PeopleManagers will be created.
  def restore_household
    restored_household = Household.new(person, maintain_sac_family: false, validate_members: false)
    family_members = expired_family_member_roles.map(&:person).uniq.presence or return
    family_members.reduce(restored_household, :add).save!(context: :create)
    restored_household.set_family_main_person!
  end

  def log_missing_membership
    HitobitoLogEntry.create!(
      category: "rechnungen",
      level: :error,
      subject: person,
      message: "Eingegangene Zahlung der Mitgliedschaftsrechnung #{year} für " \
               "#{group.layer_group} konnte keiner Mitgliedschaft zugeordnet werden."
    )
  end
end
