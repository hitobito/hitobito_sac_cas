# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


require Rails.root.join('db', 'seeds', 'support', 'group_seeder')

seeder = GroupSeeder.new

root = Group.roots.first
srand(42)

def seed_sektion(sektion)
  Group::SektionsVorstand.seed(:name, :parent_id, {
    name: 'Vorstand',
    parent_id: sektion.id
  })
  Group::SektionsHuettenKommission.seed(:name, :parent_id, {
    name: 'Hüttenkommission',
    parent_id: sektion.id
  })
  Group::SektionsTourenKommission.seed(:name, :parent_id, {
    name: 'Tourenkommission',
    parent_id: sektion.id
  })
end

def seed_hut(sektion, name)
  Group::Huette.seed(:name, :parent_id, {
    name: name,
    parent_id: sektion.id
  })
end

if root.address.blank?
  root.update(seeder.group_attributes)
  root.default_children.each do |child_class|
    child_class.first.update(seeder.group_attributes)
  end
end

['Leistungssport', 'Breitensport', 'Marketing', 'Hütten & Umwelt', 'Finanzen & Dienste', 'Digitalisierung & IT'].each do |r|
  Group::Ressort.seed(:name, :parent_id, {
    name: r,
    parent_id: root.id
  })
end

Group::ExterneKontakte.seed(:name, :parent_id, {
  name: 'Authoren',
  parent_id: Group::Ressort.find_by(name: 'Marketing').id
})

sektions = Group::Sektion.seed(
  :name, :parent_id,
  { name: 'Matterhorn',
    parent_id: root.id
  },
  { name: 'UTO',
    parent_id: root.id
  },
  { name: 'Blüemlisalp',
    parent_id: root.id
  })

sektions.each do |s|
  seed_sektion(s)
end

seed_hut(sektions.first, 'Matterhornbiwak')
seed_hut(sektions.second, 'Domhütte')
seed_hut(sektions.third, 'Blüemlisalphütte')

Group.rebuild!
