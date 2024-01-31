# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require HitobitoSacCas::Wagon.root.join('db', 'seeds', 'development', 'support', 'sac_cas_person_seeder')

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
seeder.update_mitglieder_role_dates

geschaeftsstelle = Group::Geschaeftsstelle.first
devs.each do |name, email|
  seeder.seed_developer(name, email, geschaeftsstelle, Group::Geschaeftsstelle::Admin)
end
