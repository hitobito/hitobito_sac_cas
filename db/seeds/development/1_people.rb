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

end

puzzlers = [
  'Carlo Beltrame',
  'Matthias Viehweger',
  'Micha Luedi',
  'Nils Rauch',
  'Oliver Dietschi',
  'Olivier Brian',
  'Pascal Simon',
  'Pascal Zumkehr',
  'Thomas Ellenberger',
  'Tobias Stern',
  'Tobias Hinderling'
]

devs = {
  'Stefan Sykes' => 'stefan.sykes@sac-cas.ch',
  'Daniel Menet' => 'daniel.menet@sac-cas.ch',
  'Nathalie König' => 'nathalie.koenig@sac-cas.ch',
  'Reto Giger' => 'reto.giger@sac-cas.ch',
  'Pascal Werndli' => 'pascal.werndli@sac-cas.ch',
  'Marek Polacek' => 'marek.polacek@sac-cas.ch',
}
puzzlers.each do |puz|
  devs[puz] = "#{puz.split.last.downcase}@puzzle.ch"
end

seeder = SacCasPersonSeeder.new

seeder.seed_all_roles
seeder.seed_families

geschaeftsstelle = Group::Geschaeftsstelle.first
devs.each do |name, email|
  seeder.seed_developer(name, email, geschaeftsstelle, Group::Geschaeftsstelle::ITSupport)
end
