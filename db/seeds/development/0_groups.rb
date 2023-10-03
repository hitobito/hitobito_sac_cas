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
  Group::SektionsMitglieder.seed(:name, :parent_id, {
    name: 'Mitglieder',
    parent_id: sektion.id
  })
  Group::SektionsFunktionaere.seed(:name, :parent_id, {
    name: 'Funktionäre',
    parent_id: sektion.id
  })
  Group::SektionsTourenkommission.seed(:name, :parent_id, {
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

sections = Group::Sektion.seed(
  :name, :parent_id,
  { name: 'SAC Matterhorn',
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

sections.each do |s|
  seed_sektion(s)
end

Group::SektionsNeuMitgliederSektion.seed(:name, :parent_id, {
  name: 'Neuanmeldungen',
  parent_id: sections.first.id
})

Group::SektionsNeuMitgliederZv.seed(:name, :parent_id, {
  name: 'Neuanmeldungen',
  parent_id: sections.second.id
})

Group::SektionsNeuMitgliederZv.seed(:name, :parent_id, {
  name: 'Neuanmeldungen',
  parent_id: sections.third.id
})

seed_hut(sections.first, 'Matterhornbiwak')
seed_hut(sections.second, 'Domhütte')
seed_hut(sections.second, 'Spannorthütte')
seed_hut(sections.second, 'Täschhütte')
seed_hut(sections.third, 'Blüemlisalphütte')
seed_hut(sections.third, 'Baltschiederklause')
seed_hut(sections.third, 'Stockhornbiwak')
seed_hut(sections.third, 'Gestellenhütte')
seed_hut(sections.third, 'Sunnhüsi')

Group.rebuild!
