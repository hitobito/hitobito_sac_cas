# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("db", "seeds", "support", "group_seeder")

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

ActiveRecord::Base.connection.set_pk_sequence!(:groups, 10_000)
Group::Sektion.seed_once(:id,
  {"id" => 1650,
   "navision_id" => 1650,
   "parent_id" => root.id,
   "name" => "SAC Blüemlisalp",
   "layer_group_id" => 1650,
   "street" => "Postfach",
   "zip_code" => 3600,
   "town" => "Thun",
   "foundation_year" => 1874,
   "section_canton" => "BE",
   "language" => "DE",
   "mitglied_termination_by_section_only" => true},
  {"id" => 1850,
   "navision_id" => 1850,
   "parent_id" => root.id,
   "name" => "SAC Burgdorf",
   "layer_group_id" => 1850,
   "street" => "Postfach",
   "zip_code" => 3400,
   "town" => "Burgdorf",
   "foundation_year" => 1879,
   "section_canton" => "BE",
   "language" => "DE",
   "mitglied_termination_by_section_only" => true},
  {"id" => 1900,
   "navision_id" => 1900,
   "parent_id" => root.id,
   "name" => "CAS Chasseral",
   "layer_group_id" => 1900,
   "street" => "Postfach",
   "zip_code" => 2610,
   "town" => "St-Imier",
   "foundation_year" => 1960,
   "section_canton" => "BE",
   "language" => "FR",
   "mitglied_termination_by_section_only" => false},
  {"id" => 2330,
   "navision_id" => 2330,
   "parent_id" => root.id,
   "name" => "SAC Drei Tannen",
   "layer_group_id" => 2330,
   "zip_code" => 4616,
   "town" => "Kappel SO",
   "foundation_year" => 1934,
   "section_canton" => "SO",
   "language" => "DE",
   "mitglied_termination_by_section_only" => false},
  {"id" => 5300,
   "navision_id" => 5300,
   "parent_id" => root.id,
   "name" => "SAC UTO",
   "layer_group_id" => 5300,
   "street" => "Stampfenbachstrasse",
   "housenumber" => "57",
   "zip_code" => 8006,
   "town" => "Zürich",
   "foundation_year" => 1863,
   "section_canton" => "ZH",
   "language" => "DE",
   "mitglied_termination_by_section_only" => true},
  {"id" => 5650,
   "navision_id" => 5650,
   "parent_id" => root.id,
   "name" => "CAS Yverdon",
   "layer_group_id" => 5650,
   "postbox" => "Case postale 73",
   "street" => "Rue du Collège",
   "housenumber" => "7",
   "zip_code" => 1401,
   "town" => "Yverdon",
   "foundation_year" => 1917,
   "section_canton" => "VD",
   "language" => "FR",
   "mitglied_termination_by_section_only" => true},
  {"id" => 9999,
   "navision_id" => 9999,
   "parent_id" => root.id,
   "name" => "SAC Matterhorn",
   "layer_group_id" => 9999,
   "street" => "Postfach",
   "zip_code" => 3920,
   "town" => "Zermatt",
   "foundation_year" => 1899,
   "section_canton" => "VS",
   "language" => "DE",
   "mitglied_termination_by_section_only" => true})

Group::Ortsgruppe.seed_once(:id,
  {"id" => 1853,
   "navision_id" => 1853,
   "parent_id" => 1850,
   "name" => "SAC Burgdorf Damen",
   "type" => "Group::Ortsgruppe",
   "layer_group_id" => 1853,
   "street" => "Weslen",
   "housenumber" => "101C",
   "zip_code" => 3472,
   "town" => "Wynigen",
   "foundation_year" => 1879,
   "section_canton" => "BE",
   "language" => "DE",
   "mitglied_termination_by_section_only" => true})

bluemlisalp = Group.find(1650)
matterhorn = Group.find(9999)

uto = Group::Sektion.find(5300)

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
seed_club_hut(bluemlisalp, "Blüemlisalphütte", 36)
seed_club_hut(bluemlisalp, "Baltschiederklause", 25)
seed_club_hut(bluemlisalp, "Stockhornbiwak", 258)
seed_section_hut(bluemlisalp, "Ski- & Ferienhaus Obergestelen", 448786)
seed_section_hut(bluemlisalp, "Sunnhüsi", 448785)

Group.rebuild!
