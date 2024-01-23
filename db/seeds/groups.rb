# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

root = Group::SacCas.seed_once(:parent_id, name: 'SAC/CAS').first

abonnenten = Group::Abonnenten.seed_once(:parent_id, name: 'Abonnenten', parent_id: root.id).first
Group::AboMagazin.seed_once(:parent_id, :name, name: 'Die Alpen DE', parent_id: abonnenten.id)
Group::AboMagazin.seed_once(:parent_id, :name, name: 'Les Alpes FR', parent_id: abonnenten.id)
Group::AboMagazin.seed_once(:parent_id, :name, name: 'Le Alpi IT', parent_id: abonnenten.id)
Group::AboTourenPortal.seed_once(:parent_id, :name, name: 'Touren-Portal', parent_id: abonnenten.id)
Group::AboBasicLogin.seed_once(:parent_id, :name, name: 'SAC/CAS Login', parent_id: abonnenten.id)
