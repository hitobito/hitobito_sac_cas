# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Sektion < ::Group

  self.layer = true

  ### ROLES
  class Kontaktperson < ::Role
    self.permissions = [:contact_data]
  end

  roles Kontaktperson

  children Group::SektionsVorstand, Group::SektionsMitglieder, Group::SektionsTourenKommission, Group::SektionsHuettenKommission

end
