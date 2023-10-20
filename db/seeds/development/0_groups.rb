# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('db', 'seeds', 'support', 'group_seeder')

seeder = GroupSeeder.new

root = Group.roots.first
srand(42)

def seed_hut(sektion, name, navision_id)
  Group::Huette.seed(:name, :parent_id, {
    name: name,
    navision_id: navision_id,
    parent_id: sektion.id
  })
end

if root.address.blank?
  root.update(seeder.group_attributes)
  root.default_children.each do |child_class|
    child_class.first.update(seeder.group_attributes)
  end
end

Group::Geschaeftsstelle.seed(:name, :parent_id, {
  name: '1 Geschäftsstelle',
  parent_id: root.id
})

Group::ExterneKontakte.seed(:name, :parent_id, {
  name: '2 Externe Kontakte',
  parent_id: root.id
})

Group::ExterneKontakte.seed(:name, :parent_id, {
  name: 'Autoren',
  parent_id: Group::ExterneKontakte.find_by(name: '2 Externe Kontakte').id
})

Group::ExterneKontakte.seed(:name, :parent_id, {
  name: 'Druckereien',
  parent_id: Group::ExterneKontakte.find_by(name: '2 Externe Kontakte').id
})

matterhorn, uto, bluemlisalp = *Group::Sektion.seed(
  :name, :parent_id,
  { name: 'SAC Matterhorn',
    foundation_year: 1899,
    parent_id: root.id
  },
  { name: 'SAC UTO',
    navision_id: 5300,
    foundation_year: 1863,
    parent_id: root.id
  },
  { name: 'SAC Blüemlisalp',
    navision_id: 1650,
    foundation_year: 1874,
    parent_id: root.id
  })

Group::SektionsNeuanmeldungenNv.seed_once(
  :type, :parent_id,
  { type: Group::SektionsNeuanmeldungenNv, parent_id: matterhorn.id },
)

Group::SektionsNeuanmeldungenSektion.seed_once(
  :type, :parent_id,
  { type: Group::SektionsNeuanmeldungenSektion.sti_name, parent_id: bluemlisalp.id },
)

seed_hut(matterhorn, 'Matterhornbiwak', 99999942)
seed_hut(uto, 'Domhütte', 81)
seed_hut(uto, 'Spannorthütte', 255)
seed_hut(uto, 'Täschhütte', 265)
seed_hut(bluemlisalp, 'Blüemlisalphütte', 1650)
seed_hut(bluemlisalp, 'Baltschiederklause', 25)
seed_hut(bluemlisalp, 'Stockhornbiwak', 258)
seed_hut(bluemlisalp, 'Ski- & Ferienhaus Obergestelen', 448786)
seed_hut(bluemlisalp, 'Sunnhüsi', 448785)

Group.rebuild!
