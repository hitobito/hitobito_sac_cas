# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::AboMagazin < ::Group
  ### ROLES
  class Abonnent < ::Role
    self.permissions = []
    self.basic_permissions_only = true
    self.terminatable = true

    class AbonnentBuchhand < Abonnent
    end

    class AbonnentCSS < Abonnent
    end

    class AbonnentFAT < Abonnent
    end

    class AbonnentLAV < Abonnent
    end

    class AbonnentGratis < Abonnent
    end
  end

  class Neuanmeldung < ::Role
    self.permissions = []
    self.basic_permissions_only = true

    class NeuanmeldungBuchhand < Abonnent
    end

    class NeuanmeldungCSS < Abonnent
    end

    class NeuanmeldungFAT < Abonnent
    end

    class NeuanmeldungLAV < Abonnent
    end
  end

  class Autor < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Andere < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  roles Abonnent, Neuanmeldung, Autor, Andere
end
