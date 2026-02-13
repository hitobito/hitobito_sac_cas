# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsTourenUndKurse < Group
  children Group::FreigabeKomitee,
    Group::SektionsTourenUndKurse

  ### ROLES

  class TourenleiterOhneQualifikation < ::Role
    self.permissions = [:layer_events_full]
  end

  class Tourenleiter < TourenleiterOhneQualifikation
    validate :assert_active_qualification

    private

    def assert_active_qualification
      if (start_on_changed? || new_record?) &&
          !person.qualifications.active(start_on || created_at || Time.zone.today).exists?
        errors.add(:base, :requires_active_qualification)
      end
    end
  end

  class TourenchefSommer < ::Role
    self.two_factor_authentication_enforced = true
    self.permissions = [
      :group_and_below_full,
      :layer_and_below_read,
      :layer_events_full,
      :layer_mitglieder_full
    ]
  end

  class TourenchefWinter < ::Role
    self.two_factor_authentication_enforced = true
    self.permissions = [
      :group_and_below_full,
      :layer_and_below_read,
      :layer_events_full,
      :layer_mitglieder_full
    ]
  end

  class Tourenchef < ::Role
    self.two_factor_authentication_enforced = true
    self.permissions = [
      :group_and_below_full,
      :layer_and_below_read,
      :layer_events_full,
      :layer_mitglieder_full
    ]
  end

  class KibeChef < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class FabeChef < ::Role
    self.permissions = []
    self.basic_permissions_only = true
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
    self.two_factor_authentication_enforced = true
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_and_below_full]
    self.two_factor_authentication_enforced = true
  end

  roles Tourenleiter,
    TourenleiterOhneQualifikation,
    Tourenchef,
    TourenchefSommer,
    TourenchefWinter,
    KibeChef,
    FabeChef,
    JoChef,
    JsCoach,
    Leserecht,
    Schreibrecht
end
