# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('db', 'seeds', 'support', 'person_seeder')

class SacCasPersonSeeder < PersonSeeder

  def amount(role_type)
    case role_type.name.demodulize
    when 'Member' then 5
    else 1
    end
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

geschaeftsstelle = Group::Geschaeftsstelle.first
devs.each do |name, email|
  seeder.seed_developer(name, email, geschaeftsstelle, Group::Geschaeftsstelle::ITSupport)
end
