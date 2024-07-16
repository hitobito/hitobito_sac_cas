# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsTourenUndKurse < Group
  self.static_name = true

  children Group::SektionsTourenUndKurseSommer,
    Group::SektionsTourenUndKurseWinter

  ### ROLES

  class TourenleiterOhneQualifikation < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Tourenleiter < TourenleiterOhneQualifikation
    before_validation :assert_active_qualification

    private

    def assert_active_qualification
      unless person.qualifications.active(created_at || Time.zone.today).exists?
        errors.add(:base, :requires_active_qualification)
      end
    end
  end

  class JoChef < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class JsCoach < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Leserecht < ::Role
    self.permissions = [:group_and_below_read]
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_and_below_full]
  end

  roles Tourenleiter,
    TourenleiterOhneQualifikation,
    JoChef,
    JsCoach,
    Leserecht,
    Schreibrecht
end
