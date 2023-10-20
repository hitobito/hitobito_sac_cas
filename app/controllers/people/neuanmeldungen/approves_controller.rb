# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module People
  module Neuanmeldungen
    class ApprovesController < HandlerController
      skip_authorization_check

      self.handler_class = People::Neuanmeldungen::Approve
      self.permitted_attrs = [:group_id, :ids, :locale]
    end
  end
end
