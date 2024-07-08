# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Sheet::Memberships
  class JoinZusatzsektion < Sheet::Base
    self.parent_sheet = Sheet::Person

    def initialize(*args)
      super
      @title = I18n.t(".title", scope: self.class.to_s.underscore)
    end
  end
end
