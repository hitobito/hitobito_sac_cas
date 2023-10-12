# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsNeuanmeldungenSektion < ::Group

  self.static_name = true

  validates :type, uniqueness: { scope: :parent_id }

  ### ROLES
  class Neuanmeldung < ::Role
    require_relative '../sac_cas/concerns/role_beitragskategorie'
    include ::SacCas::RoleBeitragskategorie

    self.permissions = []
    self.basic_permissions_only = true
  end

  roles Neuanmeldung
end
