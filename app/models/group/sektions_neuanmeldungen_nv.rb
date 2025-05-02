# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsNeuanmeldungenNv < ::Group
  self.static_name = true

  ### ROLES
  class Neuanmeldung < ::Role
    include SacCas::Role::MitgliedStammsektion
    include SacCas::Role::HardDestroy
    include SacCas::Role::NeuanmeldungCommon
    include SacCas::Role::NeuanmeldungStammsektion
  end

  class NeuanmeldungZusatzsektion < ::Role
    include SacCas::Role::MitgliedZusatzsektion
    include SacCas::Role::HardDestroy
    include SacCas::Role::NeuanmeldungCommon
  end

  class Leserecht < ::Role
    self.permissions = [:group_and_below_read]
    self.two_factor_authentication_enforced = true
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_and_below_full]
    self.two_factor_authentication_enforced = true
  end

  roles Neuanmeldung, NeuanmeldungZusatzsektion, Leserecht, Schreibrecht

  # make this read-only so nobody can disable self-registration on those groups
  def self_registration_role_type
    if parent.children.without_deleted.exists?(type: Group::SektionsNeuanmeldungenSektion.sti_name)
      nil
    else
      Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name
    end
  end

  # make this read-only and default for this type of group
  def self_registration_require_adult_consent
    true
  end
end
