# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
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
end
