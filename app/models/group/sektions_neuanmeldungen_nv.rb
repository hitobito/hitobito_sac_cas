# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsNeuanmeldungenNv < ::Group

  self.static_name = true

  ### ROLES
  class Neuanmeldung < ::Role
    include SacCas::Role::MitgliedHauptsektion
    include SacCas::Role::HardDestroy
  end

  class NeuanmeldungZusatzsektion < ::Role
    include SacCas::Role::MitgliedZusatzsektion
  end

  roles Neuanmeldung, NeuanmeldungZusatzsektion

  # make this read-only so nobody can disable self-registration on those groups
  def self_registration_role_type
    if parent.children.pluck(:type).include?(Group::SektionsNeuanmeldungenSektion.sti_name)
      nil
    else
      Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name
    end
  end
end
