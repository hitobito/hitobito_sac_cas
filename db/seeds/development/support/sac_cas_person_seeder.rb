# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('db', 'seeds', 'support', 'person_seeder')

class SacCasPersonSeeder < PersonSeeder

  def amount(role_type)
    case role_type.name.demodulize
    when 'Mitglied' then 42
    when 'Neuanmeldung' then 3
    when 'Beguenstigt' then 0
    when 'Ehrenmitglied' then 0
    when 'Tourenleiter' then 12
    when 'Abonnent' then 42
    when 'BasicLogin' then 42
    else 1
    end
  end

  def seed_role(person, group, role_type, **opts)
    super unless role_type < ::SacCas::RoleBeitragskategorie

    person.update!(birthday: (6..72).to_a.sample.years.ago)
    cat = ::SacCas::Beitragskategorie::Calculator.new(person).calculate
    super(person, group, role_type, **opts.merge(beitragskategorie: cat))
  end

  def person_attributes(role_type)
    attrs = super
    attrs.delete(:nickname)
    attrs
  end

  def seed_families
    Group::SektionsMitglieder.find_each do |m|
      adult = seed_sac_adult
      second_adult = seed_sac_adult
      child = seed_sac_child

      family_members = [adult, second_adult, child]

      # skip if already in a household / family
      return if family_members.any?(&:household_key)

      create_or_update_household(adult, second_adult)
      create_or_update_household(adult, child)

      family_members.each do |p|
        # make sure this person has no other roles
        p.roles.find_each {|r| r.really_destroy!}
        seed_sektion_familie_mitglied_role(p, m)
      end
    end
  end

  def seed_sektion_familie_mitglied_role(person, sektion)
    Group::SektionsMitglieder::Mitglied.seed(:person_id, person: person, group: sektion, beitragskategorie: :familie)
  end

  def create_or_update_household(person, second_person)
    household = Person::Household.new(person, Ability.new(Person.root), second_person, Person.root)
    household.assign
    household.save
  end

  def seed_sac_adult
    adult_attrs = standard_attributes(Faker::Name.first_name,
                                      Faker::Name.last_name)
    adult_attrs = adult_attrs.merge({ birthday: 27.years.ago })
    adult = Person.seed(:email, adult_attrs).first
    seed_accounts(adult, false)
    adult
  end

  def seed_sac_child
    child_attrs = standard_attributes(Faker::Name.first_name,
                                      Faker::Name.last_name)
    child_attrs.delete(:email)
    child_attrs = child_attrs.merge({ birthday: 10.years.ago })
    child = Person.seed(:first_name, child_attrs).first
    child
  end

  # for mitglieder roles, from/to has to be set to be valid
  def update_mitglieder_role_dates
    update_role_dates(Group::SektionsMitglieder::Mitglied)
    Group::SektionsMitglieder::MitgliedZusatzsektion.all.find_each do |r|
      create_stammsektion_role(r)
      stamm_role = r.person.roles.find_by(type: 'Group::SektionsMitglieder::Mitglied')
      r.update!(created_at: stamm_role.created_at, delete_on: stamm_role.delete_on)
    end
  end

  def seed_some_ehrenmitglieder_beguenstigt_roles
    return unless Group::SektionsMitglieder::Ehrenmitglied.count.zero?

    mitglied_role_types = [Group::SektionsMitglieder::Mitglied,
                           Group::SektionsMitglieder::MitgliedZusatzsektion].each(&:sti_name)
    mitglied_role_ids = Role.where(type: mitglied_role_types).pluck(:person_id, :group_id).sample(21)
    mitglied_role_ids.each do |person_id, group_id|
      if rand(2) == 1
        Group::SektionsMitglieder::Ehrenmitglied.create!(person_id: person_id, group_id: group_id)
      else
        Group::SektionsMitglieder::Beguenstigt.create!(person_id: person_id, group_id: group_id)
      end
    end
  end

  private

  def create_stammsektion_role(zusatzsektion_role)
    # check if person has stammsektion already
    return if zusatzsektion_role.person.roles.any? do |r|
      r.type == 'Group::SektionsMitglieder::Mitglied'
    end

    # create stammsektion role in other sektion than zusatzsektion role
    sektion = zusatzsektion_role.group
    mitglieder_groups = Group::SektionsMitglieder.where.not(id: sektion.id)
    person = zusatzsektion_role.person
    Group::SektionsMitglieder::Mitglied.create!(
      person: person,
      group: mitglieder_groups.sample,
      created_at: membership_from(person),
      delete_on: Date.today.end_of_year)
  end

  def update_role_dates(role_class)
    role_class.find_each do |r|
      yield(r) if block_given?
      r.update!(created_at: membership_from(r.person),
                delete_on: Date.today.end_of_year)
    end
  end

  # returns random membership entry date concerning
  # the person's age
  def membership_from(person)
    # 6 years is sac min age for membership
    max_years = person.years - 6
    if max_years > 1
      (1..max_years).to_a.sample.years.ago
    else
      (1..11).to_a.sample.months.ago
    end 
  end
end
