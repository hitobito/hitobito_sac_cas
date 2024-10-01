# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("db", "seeds", "support", "group_seeder")

SacImports::SacSectionsImporter.new(import_spec_fixture: true).create
seeder = GroupSeeder.new

root = Group.roots.first
srand(42)

def seed_club_hut(sektion, name, navision_id)
  sektions_funktionaere = Group::SektionsFunktionaere.find_or_create_by(parent_id: sektion.id)
  kommissionen = Group::SektionsKommissionen.find_or_create_by(parent_id: sektions_funktionaere.id)
  Group::SektionsKommissionHuetten.find_or_create_by(parent_id: kommissionen.id)
  clubhuetten = Group::SektionsClubhuetten.find_or_create_by(parent_id: sektions_funktionaere.id)
  Group::SektionsClubhuette.seed(:name, :parent_id, {
    name: name,
    navision_id: navision_id,
    parent: clubhuetten
  })
end

def seed_section_hut(sektion, name, navision_id)
  sektions_funktionaere = Group::SektionsFunktionaere.find_or_create_by(parent_id: sektion.id)
  kommissionen = Group::SektionsKommissionen.find_or_create_by(parent_id: sektions_funktionaere.id)
  Group::SektionsKommissionHuetten.find_or_create_by(parent_id: kommissionen.id)
  sektionshuetten = Group::Sektionshuetten.find_or_create_by(parent_id: sektions_funktionaere.id)
  Group::Sektionshuette.seed(:name, :parent_id, {
    name: name,
    navision_id: navision_id,
    parent: sektionshuetten
  })
end

if root.address.blank?
  root.update(seeder.group_attributes)
  root.default_children.each do |child_class|
    child_class.first.update(seeder.group_attributes)
  end
end

Group::Geschaeftsstelle.seed_once(:parent_id, {
  parent_id: root.id
})

Group::Geschaeftsleitung.seed_once(:parent_id, {
  parent_id: root.id
})

Group::ExterneKontakte.seed_once(:name, :parent_id, {
  name: "2 Externe Kontakte",
  parent_id: root.id
})

Group::ExterneKontakte.seed_once(:name, :parent_id, {
  name: "Autoren",
  parent_id: Group::ExterneKontakte.find_by(name: "2 Externe Kontakte").id
})

Group::ExterneKontakte.seed_once(:name, :parent_id, {
  name: "Druckereien",
  parent_id: Group::ExterneKontakte.find_by(name: "2 Externe Kontakte").id
})

bluemlisalp = Group.find_by(navision_id: 1650)
matterhorn = Group.find_by(navision_id: 9999)

uto = Group::Sektion.seed(
  :name, :parent_id,
  {name: "SAC UTO",
   navision_id: 5300,
   foundation_year: 1863,
   section_canton: "ZH",
   parent_id: root.id}
).first

matterhorn_neuanmeldungen = Group::SektionsNeuanmeldungenNv.find_by(parent_id: matterhorn.id)
matterhorn_neuanmeldungen.update!(
  custom_self_registration_title: "Registrierung zu SAC Matterhorn",
  self_registration_role_type: Group::SektionsNeuanmeldungenNv::Neuanmeldung
)

Group::SektionsNeuanmeldungenSektion.seed_once(
  :type, :parent_id,
  {type: Group::SektionsNeuanmeldungenSektion.sti_name,
   parent_id: bluemlisalp.id,
   custom_self_registration_title: "Registrierung zu SAC Blüemlisalp",
   self_registration_role_type: Group::SektionsNeuanmeldungenSektion::Neuanmeldung}
)

seed_section_hut(matterhorn, "Matterhornbiwak", 99999942)
seed_club_hut(uto, "Domhütte", 81)
seed_club_hut(uto, "Spannorthütte", 255)
seed_club_hut(uto, "Täschhütte", 265)
seed_club_hut(bluemlisalp, "Blüemlisalphütte", 1650)
seed_club_hut(bluemlisalp, "Baltschiederklause", 25)
seed_club_hut(bluemlisalp, "Stockhornbiwak", 258)
seed_section_hut(bluemlisalp, "Ski- & Ferienhaus Obergestelen", 448786)
seed_section_hut(bluemlisalp, "Sunnhüsi", 448785)

Group.rebuild!
