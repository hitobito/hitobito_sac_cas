# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsTourenkommission < Group

  self.static_name = true

  ### ROLES
  class Tourenchef < ::Role
    self.permissions = [:group_full]
    self.two_factor_authentication_enforced = true
  end

  class TourenchefSommer < Tourenchef; end
  class TourenchefWinter < Tourenchef; end
  class TourenchefKlettern < Tourenchef; end
  class TourenchefSenioren < Tourenchef; end

  class Tourenleiter < ::Role
    self.permissions = []
    self.basic_permissions_only = true

    before_validation :assert_active_qualification

    private

    def assert_active_qualification
      unless person.qualifications.active(created_at || Time.zone.today).exists?
        errors.add(:base, :requires_active_qualification)
      end
    end
  end

  roles TourenchefSommer,
        TourenchefWinter,
        TourenchefKlettern,
        TourenchefSenioren,
        Tourenleiter

end
