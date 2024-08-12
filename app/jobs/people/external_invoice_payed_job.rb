class People::ExternalInvoicePayedJob < BaseJob

  def initialize(person, link, year)
    @person = person
    @link = link
    @year = year

    context = Invoices::SacMemberships::Context.new(Time.zone.today)
    @member ||= Invoices::SacMemberships::Member.new(person, context)
  end

  def perform
    if link_to_stammsektion?
      update_role_dates
    elsif link_to_neuanmeldung_stammsektion?
      @person.confirmed_at = Time.zone.now unless @person.confirmed_at.present?
      create_stammsektion_role(@person)
      create_family_stammsektion_role if family_main_person?
    elsif link_to_neuanmeldung_zusatzsektion?
      create_zusatzsektion_roles(@person)
      create_family_zusatzsektion_roles if family_main_person?
    end
  end

  private

  def update_role_dates
    roles_for_update = []

    roles_for_update << @person.sac_membership.stammsektion_role
    roles_for_update.concat(@person.sac_membership.zusatzsektion_roles.reject { |zusatzsektion| zusatzsektion.terminated? })
    if family_main_person?
      roles_for_update.concat(@member.family_members.map(&:sac_membership).map(&:stammsektion_role))
      roles_for_update.concat(@member.family_members
                                 .map(&:sac_membership)
                                 .flat_map(&:zusatzsektion_roles)
                                 .select { |zusatzsektion| zusatzsektion.beitragskategorie == "family" })
    end

    roles_for_update.each do |role|
      role.update!(delete_on: Date.new(@year).end_of_year) unless role.delete_on.year >= @year
    end
  end

  def create_stammsektion_role(person)
    person.sac_membership.neuanmeldung_stammsektion_role.destroy
    Group::SektionsMitglieder::Mitglied.create!(person: person, group: @link.layer_group.children.where(type: Group::SektionsMitglieder.sti_name).first, delete_on: Date.new(@year).end_of_year, created_at: Time.zone.now)
  end

  def create_family_stammsektion_role
    @person.household_people.each do |family_member|
      create_stammsektion_role(family_member)
    end
  end

  def create_zusatzsektion_roles(person)
    person.sac_membership.neuanmeldung_zusatzsektion_roles.each do |role|
      role.destroy
      Group::SektionsMitglieder::MitgliedZusatzsektion.create!(person: person, group: @link.layer_group.children.where(type: Group::SektionsMitglieder.sti_name).first, delete_on: Date.new(@year).end_of_year, created_at: Time.zone.now)
    end
  end

  def create_family_zusatzsektion_roles
    @person.household_people.each do |family_member|
      create_zusatzsektion_roles(family_member)
    end
  end

  def link_to_stammsektion?
    @person.sac_membership.active? && @person.sac_membership.stammsektion_role.layer_group == @link.layer_group
  end

  def link_to_neuanmeldung_stammsektion?
    @person.sac_membership.neuanmeldung_stammsektion_role&.layer_group == @link.layer_group
  end

  def link_to_neuanmeldung_zusatzsektion?
    @person.sac_membership.neuanmeldung_zusatzsektion_roles.first.layer_group == @link.layer_group
  end

  def family_main_person?
    @person.sac_family_main_person?
  end
end

