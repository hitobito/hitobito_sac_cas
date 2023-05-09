# frozen_string_literal: true
# encoding: utf-8

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
  'Andreas Maierhofer',
  'Carlo Beltrame',
  'Mathis Hofer',
  'Matthias Viehweger',
  'Nils Rauch',
  'Olivier Brian',
  'Pascal Simon',
  'Pascal Zumkehr',
  'Roland Studer',
  'Tobias Hinderling',
  'Severin Raez'
]

devs = {
  'Customer Name' => 'customer@email.com'
}
puzzlers.each do |puz|
  devs[puz] = "#{puz.split.last.downcase}@puzzle.ch"
end

seeder = SacCasPersonSeeder.new

seeder.seed_all_roles

root = Group.root
devs.each do |name, email|
  seeder.seed_developer(name, email, root, Group::Root::Leader)
end
