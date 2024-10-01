# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

def seed_magazin_abo(name, parent)
  Group::AboMagazin.seed_once(:parent_id, :name) do |a|
    a.parent_id = parent.id
    a.name = name
    a.self_registration_role_type = "Group::AboMagazin::Abonnent"
  end
end

Group::SacCas.seed_once(:name, name: "SAC/CAS")

Group::Abos.seed_once(:parent_id, parent_id: Group.root.id)
abos = Group::Abos.find_by(parent_id: Group.root.id)

Group::AboMagazine.seed_once(:parent_id, parent_id: abos.id)
magazine = Group::AboMagazine.find_by(parent_id: abos.id)

seed_magazin_abo("Die Alpen DE", magazine)
seed_magazin_abo("Les Alpes FR", magazine)
seed_magazin_abo("Le Alpi IT", magazine)

Group::AboTourenPortal.seed_once(:parent_id) do |a|
  a.parent_id = abos.id
  a.self_registration_role_type = "Group::AboTourenPortal::Abonnent"
end

Group::AboBasicLogin.seed_once(:parent_id) do |a|
  a.parent_id = abos.id
  a.self_registration_role_type = "Group::AboBasicLogin::BasicLogin"
end
