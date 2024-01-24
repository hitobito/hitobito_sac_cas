# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

Group::SacCas.seed_once(:parent_id, name: 'SAC/CAS')

Group::Abonnenten.seed_once(:parent_id, parent_id: Group.root.id)
abonnenten = Group::Abonnenten.find_by(parent_id: Group.root.id)
Group::AboMagazin.seed_once(:parent_id, :name, name: 'Die Alpen DE', parent_id: abonnenten.id)
Group::AboMagazin.seed_once(:parent_id, :name, name: 'Les Alpes FR', parent_id: abonnenten.id)
Group::AboMagazin.seed_once(:parent_id, :name, name: 'Le Alpi IT', parent_id: abonnenten.id)
Group::AboTourenPortal.seed_once(:parent_id, parent_id: abonnenten.id)
Group::AboBasicLogin.seed_once(:parent_id, parent_id: abonnenten.id)
